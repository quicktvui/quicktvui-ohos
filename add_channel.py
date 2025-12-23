import os
import shutil
import json
import re
import subprocess

# ================= 配置路径 =================
PROJECT_ROOT = os.getcwd()
# 根据您的实际情况，如果是直接在 quicktvui_ohos 目录下运行，则是 runtime
# 如果是在项目根目录运行且有一层 quicktvui_ohos 文件夹，请修改为 os.path.join(PROJECT_ROOT, "quicktvui_ohos", "runtime")
RUNTIME_MODULE_PATH = os.path.join(PROJECT_ROOT, "runtime")
SIGN_PATH = os.path.join(PROJECT_ROOT, "sign")

# build-profile.json5 文件路径
RUNTIME_PROFILE = os.path.join(RUNTIME_MODULE_PATH, "build-profile.json5")
ROOT_PROFILE = os.path.join(PROJECT_ROOT, "build-profile.json5")

# 模版路径
RUNTIME_TEMPLATE_SRC = os.path.join(RUNTIME_MODULE_PATH, "src", "template")
SIGN_TEMPLATE_SRC = os.path.join(SIGN_PATH, "template")

def print_color(text, color="green"):
    colors = {"green": "\033[92m", "red": "\033[91m", "yellow": "\033[93m", "reset": "\033[0m"}
    print(f"{colors.get(color, '')}{text}{colors['reset']}")

def get_signing_config_name(channel_name):
    if channel_name.startswith("g_"):
        return channel_name[2:]
    return channel_name

def extract_template_block(content, search_pattern, start_search_index=0):
    match = re.search(search_pattern, content[start_search_index:])
    if not match: return None, -1

    keyword_absolute_index = start_search_index + match.start()

    # 1. 向前找 {
    start_brace_index = -1
    open_brackets = 0
    for i in range(keyword_absolute_index, -1, -1):
        char = content[i]
        if char == '}': open_brackets += 1
        elif char == '{':
            if open_brackets == 0:
                start_brace_index = i
                break
            open_brackets -= 1
    if start_brace_index == -1: return None, -1

    # 2. 向后找 }
    end_brace_index = -1
    brace_stack = 0
    in_string = False
    string_char = '"'

    for i in range(start_brace_index, len(content)):
        char = content[i]
        if char == '"' or char == "'":
            if not in_string: in_string = True; string_char = char
            elif char == string_char and content[i-1] != '\\': in_string = False
        if in_string: continue

        if char == '{': brace_stack += 1
        elif char == '}':
            brace_stack -= 1
            if brace_stack == 0:
                end_brace_index = i
                break

    if end_brace_index == -1: return None, -1
    return content[start_brace_index : end_brace_index + 1], end_brace_index

def find_array_closing_bracket(content, start_search_index):
    stack_curly = 0; stack_square = 0; in_string = False; string_char = '"'
    for i in range(start_search_index, len(content)):
        char = content[i]
        if char == '"' or char == "'":
            if not in_string: in_string = True; string_char = char
            elif char == string_char and content[i-1] != '\\': in_string = False
        if in_string: continue

        if char == '{': stack_curly += 1
        elif char == '}': stack_curly -= 1
        elif char == '[': stack_square += 1
        elif char == ']':
            if stack_curly == 0 and stack_square == 0: return i
            stack_square -= 1
    return -1

def smart_append_node(file_path, identifier_pattern, replacements, scope_pattern=None):
    try:
        with open(file_path, 'r', encoding='utf-8') as f: content = f.read()

        # 1. 确定搜索范围 (Scope)
        search_start_idx = 0
        if scope_pattern:
            scope_match = re.search(scope_pattern, content)
            if not scope_match:
                print_color(f"错误: 未找到作用域 {scope_pattern}", "red"); return
            search_start_idx = scope_match.end()

        # 2. 提取模版
        template_block, template_end_idx = extract_template_block(content, identifier_pattern, search_start_idx)
        if not template_block:
            print_color(f"错误: 未找到模版节点 {identifier_pattern}", "red"); return

        # 3. 寻找数组结束位置 (用于查重和插入)
        insert_idx = find_array_closing_bracket(content, template_end_idx + 1)
        if insert_idx == -1:
            print_color(f"错误: 无法定位数组结束位置", "red"); return

        # 4. 生成新块
        new_block = template_block
        for old_str, new_str in replacements.items():
            new_block = new_block.replace(old_str, new_str)

        # 5. 【修复核心】查重 - 只在当前数组范围内查重！
        name_match = re.search(r'"name"\s*:\s*"(.*?)"', new_block)
        if name_match:
            new_name = name_match.group(1)
            # 截取从 scope 开始到 数组结束 的内容进行检查
            scope_content = content[search_start_idx : insert_idx]
            if f'"name": "{new_name}"' in scope_content:
                print_color(f"跳过: 当前数组中已存在 name: {new_name}", "yellow")
                return

        # 6. 插入
        insertion_str = f",\n{new_block}\n"
        final_content = content[:insert_idx] + insertion_str + content[insert_idx:]

        with open(file_path, 'w', encoding='utf-8') as f: f.write(final_content)
        print(f"已更新: {os.path.basename(file_path)} -> 添加 {new_name}")

    except Exception as e:
        print_color(f"处理文件 {file_path} 失败: {e}", "red")

def run_git_add(paths):
    """ 执行 git add 命令 """
    print_color("\n=== 执行 Git Add ===", "yellow")

    # 过滤掉不存在的路径
    valid_paths = [p for p in paths if os.path.exists(p)]

    if not valid_paths:
        print_color("没有文件需要添加到 Git", "yellow")
        return

    try:
        # 打印即将添加的文件
        print("正在添加以下文件/目录:")
        for p in valid_paths:
            print(f" - {os.path.relpath(p, PROJECT_ROOT)}") # 显示相对路径

        # 执行命令
        subprocess.run(["git", "add"] + valid_paths, check=True)
        print_color("Git Add 执行成功!", "green")
    except subprocess.CalledProcessError as e:
        print_color(f"Git Add 执行失败: {e}", "red")
    except FileNotFoundError:
        print_color("错误: 未找到 git 命令，请确认已安装 git。", "red")
    except Exception as e:
        print_color(f"发生错误: {e}", "red")

def main():
    print_color("=== HarmonyOS 渠道添加脚本 (Git版) ===", "green")

    channel_name = input("请输入渠道名称 (例如 book): ").strip()
    if not channel_name: return

    app_label = input(f"请输入应用名称: ").strip()

    sign_config_name = get_signing_config_name(channel_name)
    target_bundle_name = f"tv.huan.{channel_name}.hmos"

    print_color(f"\n配置: {channel_name} | {sign_config_name}", "yellow")
    if input("确认继续? (y/n): ").lower() != 'y': return

    # 1. 拷贝资源
    target_runtime_src = os.path.join(RUNTIME_MODULE_PATH, "src", channel_name)
    if not os.path.exists(target_runtime_src):
        try:
            shutil.copytree(RUNTIME_TEMPLATE_SRC, target_runtime_src)
            s_path = os.path.join(target_runtime_src, "resources", "base", "element", "string.json")
            if os.path.exists(s_path):
                with open(s_path, 'r', encoding='utf-8') as f: data = json.load(f)
                for item in data.get("string", []):
                    if item.get("name") == "app_name": item["value"] = app_label
                with open(s_path, 'w', encoding='utf-8') as f: json.dump(data, f, ensure_ascii=False, indent=2)
            print("资源已拷贝")
        except: pass

    target_sign_path = os.path.join(SIGN_PATH, channel_name)
    if not os.path.exists(target_sign_path):
        try: shutil.copytree(SIGN_TEMPLATE_SRC, target_sign_path); print("签名已拷贝")
        except: pass

    # 2. 修改 JSON

    # Runtime Targets
    smart_append_node(
        RUNTIME_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{channel_name}"',
            '/src/template/': f'/src/{channel_name}/'
        },
        scope_pattern=r'"targets"\s*:\s*\['
    )

    # Root Products
    smart_append_node(
        ROOT_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{channel_name}"',
            '"signingConfig": "template"': f'"signingConfig": "{sign_config_name}"',
            'tv.huan.template.hmos': target_bundle_name
        },
        scope_pattern=r'"products"\s*:\s*\['
    )

    # Root SigningConfigs
    smart_append_node(
        ROOT_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{sign_config_name}"',
            'sign/template/': f'sign/{channel_name}/',         # 匹配您提供的JSON格式
            'sign_private/template/': f'sign_private/{channel_name}/' # 兼容另一种格式
        },
        scope_pattern=r'"signingConfigs"\s*:\s*\['
    )

    # Root Runtime Module Targets
    smart_append_node(
        ROOT_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{channel_name}"',
            '"template"': f'"{channel_name}"'
        },
        scope_pattern=r'"modules"[\s\S]*?"targets"\s*:\s*\['
    )

    print_color("文件操作完成", "green")

    # ================= 3. 执行 Git Add =================
    # 收集需要添加的路径
    git_paths = [
        RUNTIME_PROFILE,        # 修改的 runtime/build-profile.json5
        ROOT_PROFILE,           # 修改的 build-profile.json5
        target_runtime_src,     # 新增的 src/xxx 文件夹
        target_sign_path        # 新增的 sign/xxx 文件夹
    ]

    run_git_add(git_paths)

    # ================= 4. 重要提醒 =================
    print_color("\n" + "="*20 + " 重 要 提 醒 " + "="*20, "red")
    print(f"1. [图标] 请替换: runtime/src/{channel_name}/resources/base/media/app_icon.png")
    print(f"2. [代码] 请添加快应用代码到: runtime/src/{channel_name}/rawfile/vue")
    print(f"3. [签名] 脚本已拷贝了测试签名到: sign/{channel_name}")
    print(f"   注意：请务必将该文件夹下的文件替换为【正式签名文件】。")
    print(f"4. [路径] 请确认 build-profile 中 'signingConfigs' 与实际目录 'sign' 的映射关系。")
    print_color("="*50, "red")

if __name__ == "__main__":
    main()