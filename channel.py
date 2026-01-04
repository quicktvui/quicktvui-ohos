import os
import shutil
import json
import re
import subprocess

# ================= 配置路径 =================
PROJECT_ROOT = os.getcwd()
RUNTIME_MODULE_PATH = os.path.join(PROJECT_ROOT, "runtime")
SIGN_PATH = os.path.join(PROJECT_ROOT, "sign")
CHANNEL_CONFIG_FILE = os.path.join(PROJECT_ROOT, "channels.json")

# build-profile.json5 文件路径
RUNTIME_PROFILE = os.path.join(RUNTIME_MODULE_PATH, "build-profile.json5")
ROOT_PROFILE = os.path.join(PROJECT_ROOT, "build-profile.json5")

# 模版路径
RUNTIME_TEMPLATE_SRC = os.path.join(RUNTIME_MODULE_PATH, "src", "template")
SIGN_TEMPLATE_SRC = os.path.join(SIGN_PATH, "template")

# 模版中的默认包名（用于查找并替换为新包名）
TEMPLATE_BUNDLE_NAME = "tv.huan.template.hmos"

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
                print_color(f"错误: 未找到作用域 {scope_pattern} in {os.path.basename(file_path)}", "red"); return
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

        # 5. 查重 - 只在当前数组范围内查重
        name_match = re.search(r'"name"\s*:\s*"(.*?)"', new_block)
        if name_match:
            new_name = name_match.group(1)
            # 截取从 scope 开始到 数组结束 的内容进行检查
            scope_content = content[search_start_idx : insert_idx]
            if f'"name": "{new_name}"' in scope_content:
                print_color(f"跳过: {os.path.basename(file_path)} 中已存在 name: {new_name}", "yellow")
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
    valid_paths = [p for p in paths if os.path.exists(p)]
    if not valid_paths: return

    try:
        # 去重
        valid_paths = list(set(valid_paths))
        # 执行命令
        subprocess.run(["git", "add"] + valid_paths, check=True)
        print_color(f"Git Add 成功添加了 {len(valid_paths)} 个文件/目录", "green")
    except Exception as e:
        print_color(f"Git Add 执行失败: {e}", "red")

def process_channel(item):
    channel_name = item.get("channel")
    package_name = item.get("package")
    # 如果json里有name字段则使用，否则使用channel名作为应用名
    app_label = item.get("name", channel_name)

    if not channel_name or not package_name:
        print_color(f"跳过无效数据: {item}", "red")
        return []

    print_color(f"\n正在处理渠道: {channel_name} | 包名: {package_name}", "green")

    sign_config_name = get_signing_config_name(channel_name)
    created_paths = []

    # 1. 拷贝资源 (Runtime SRC)
    target_runtime_src = os.path.join(RUNTIME_MODULE_PATH, "src", channel_name)
    if not os.path.exists(target_runtime_src):
        try:
            shutil.copytree(RUNTIME_TEMPLATE_SRC, target_runtime_src)
            # 修改 string.json 中的 app_name
            s_path = os.path.join(target_runtime_src, "resources", "base", "element", "string.json")
            if os.path.exists(s_path):
                with open(s_path, 'r', encoding='utf-8') as f: data = json.load(f)
                for str_item in data.get("string", []):
                    if str_item.get("name") == "app_name":
                        str_item["value"] = app_label
                with open(s_path, 'w', encoding='utf-8') as f: json.dump(data, f, ensure_ascii=False, indent=2)
            created_paths.append(target_runtime_src)
            print(f"资源已拷贝: src/{channel_name}")
        except Exception as e:
            print_color(f"拷贝资源失败: {e}", "red")
    else:
        created_paths.append(target_runtime_src) # 即使存在也加入git add列表

    # 2. 拷贝签名 (Sign)
    target_sign_path = os.path.join(SIGN_PATH, channel_name)
    if not os.path.exists(target_sign_path):
        try:
            shutil.copytree(SIGN_TEMPLATE_SRC, target_sign_path)
            created_paths.append(target_sign_path)
            print(f"签名已拷贝: sign/{channel_name}")
        except Exception as e:
            print_color(f"拷贝签名失败: {e}", "red")
    else:
        created_paths.append(target_sign_path)

    # 3. 修改 JSON - Runtime Targets
    smart_append_node(
        RUNTIME_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{channel_name}"',
            '/src/template/': f'/src/{channel_name}/'
        },
        scope_pattern=r'"targets"\s*:\s*\['
    )

    # 4. 修改 JSON - Root Products
    # 注意：这里将 TEMPLATE_BUNDLE_NAME 替换为 package_name
    # 这样 buildProfileFields 中的 APP_ID 和 bundleName 都会被同时修改
    smart_append_node(
        ROOT_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{channel_name}"',
            '"signingConfig": "template"': f'"signingConfig": "{sign_config_name}"',
            TEMPLATE_BUNDLE_NAME: package_name
        },
        scope_pattern=r'"products"\s*:\s*\['
    )

    # 5. 修改 JSON - Root SigningConfigs
    smart_append_node(
        ROOT_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{sign_config_name}"',
            'sign/template/': f'sign/{channel_name}/',
            'sign_private/template/': f'sign_private/{channel_name}/'
        },
        scope_pattern=r'"signingConfigs"\s*:\s*\['
    )

    # 6. 修改 JSON - Root Modules -> targets
    smart_append_node(
        ROOT_PROFILE,
        identifier_pattern=r'"name"\s*:\s*"template"',
        replacements={
            '"name": "template"': f'"name": "{channel_name}"',
            '"template"': f'"{channel_name}"'
        },
        scope_pattern=r'"modules"[\s\S]*?"targets"\s*:\s*\['
    )

    return created_paths

def main():
    print_color("=== HarmonyOS 批量渠道添加脚本 (JSON版) ===", "green")

    if not os.path.exists(CHANNEL_CONFIG_FILE):
        print_color(f"错误: 未找到配置文件 {CHANNEL_CONFIG_FILE}", "red")
        print("请创建一个 channels.json 文件，格式为: [{'channel': 'xxx', 'package': 'xxx'}]")
        return

    try:
        with open(CHANNEL_CONFIG_FILE, 'r', encoding='utf-8') as f:
            channels_list = json.load(f)
    except Exception as e:
        print_color(f"读取配置文件失败: {e}", "red")
        return

    print(f"读取到 {len(channels_list)} 个渠道配置，准备处理...")

    all_git_paths = [RUNTIME_PROFILE, ROOT_PROFILE]

    for item in channels_list:
        new_paths = process_channel(item)
        all_git_paths.extend(new_paths)

    # 执行 Git Add
    if input("\n是否执行 git add? (y/n): ").lower() == 'y':
        run_git_add(all_git_paths)

    print_color("\n" + "="*50, "green")
    print_color("批量处理完成！请检查生成的文件。", "green")
    print_color("="*50, "green")

if __name__ == "__main__":
    main()