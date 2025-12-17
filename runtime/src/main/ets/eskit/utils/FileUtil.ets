import { cryptoFramework } from '@kit.CryptoArchitectureKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { buffer } from '@kit.ArkTS';

export class FileUtil {
  static async calFileMd5(fileUrl: string) {
    let md = cryptoFramework.createMd('MD5');
    let file = fs.openSync(fileUrl, fs.OpenMode.READ_ONLY);
    let arrayBuffer = new ArrayBuffer(2048);
    let len: number = 0;
    let position: number = 0;
    do {
      len = fs.readSync(file.fd, arrayBuffer, { offset: position });
      if (len > 0) {
        let uint8Array = new Uint8Array(arrayBuffer.slice(0, len));
        let updateMessageBlob: cryptoFramework.DataBlob = { data: uint8Array };
        await md.update(updateMessageBlob);
        position += len;
      }
    } while (len > 0);
    fs.closeSync(file);
    let mdOutput = await md.digest();
    const calFileMd5 = buffer.from(mdOutput.data).toString('hex');
    return calFileMd5;
  }

  /**
   * ArkTS 版的 decryptRpk 实现
   * 读取 originFile，交换首尾 100 字节，写入 decryptFile
   */
  static async decryptRpk(originPath: string, decryptPath: string): Promise<void> {
    try {
      // 1. 读取源文件
      let srcFile = await fs.open(originPath, fs.OpenMode.READ_ONLY);
      let stat = await fs.stat(srcFile.fd);
      // 注意：如果文件特别大，建议不要一次性 new ArrayBuffer，而是分块读写。
      // 这里假设 RPK 文件大小适中（几十MB以内），保持原 Java 逻辑一次性读入。
      let buffer = new ArrayBuffer(stat.size);

      await fs.read(srcFile.fd, buffer);
      await fs.close(srcFile);

      // 2. 字节交换逻辑
      let bytes = new Uint8Array(buffer);
      const len = bytes.length;
      const loopCount = 100;

      for (let i = 0; i < loopCount; i++) {
        // 防止文件极小越界
        if (i >= len) {
          break;
        }

        let tmp = bytes[i];
        let targetIndex = len - i - 1;

        if (targetIndex >= 0 && targetIndex < len) {
          bytes[i] = bytes[targetIndex];
          bytes[targetIndex] = tmp;
        }
      }
      // 3. 写入目标文件
      // CREATE: 不存在则创建, TRUNC: 存在则清空重写
      let destFile = await fs.open(decryptPath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      await fs.write(destFile.fd, buffer);
      await fs.close(destFile);

    } catch (e) {
      // 异常时尝试清理
      FileUtil.cleanFile(decryptPath);
      throw new Error(`Decrypt RPK failed: ${e.message}`);
    }
  }

  // 辅助清理文件方法
  static cleanFile(path: string) {
    try {
      if (fs.accessSync(path)) {
        fs.unlinkSync(path);
      }
    } catch (ignore) {
    }
  }
}

