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
}