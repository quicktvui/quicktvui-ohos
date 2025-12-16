import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';
import { BusinessError } from '@kit.BasicServicesKit';

export class SignUtil {
  static PUB_KEY_BUFFER =
    new Uint8Array([48, 129, 159, 48, 13, 6, 9, 42, 134, 72, 134, 247, 13, 1, 1, 1, 5, 0, 3, 129, 141, 0, 48, 129,
      137, 2, 129, 129, 0, 230, 208, 95, 85, 161, 188, 253, 135, 232, 60, 252, 225, 172, 115, 216, 106, 221, 37,
      166, 15, 214, 178, 238, 10, 158, 237, 241, 10, 221, 65, 83, 209, 45, 175, 234, 217, 10, 107, 219, 187, 177,
      229, 154, 19, 204, 210, 47, 172, 32, 89, 167, 95, 185, 235, 95, 88, 59, 79, 136, 24, 78, 42, 82, 246, 69, 8,
      44, 215, 120, 112, 106, 144, 225, 155, 191, 128, 34, 183, 126, 115, 31, 236, 65, 126, 65, 150, 62, 178, 173,
      94, 112, 63, 48, 170, 151, 116, 170, 40, 116, 103, 241, 26, 77, 34, 225, 200, 124, 189, 127, 65, 17, 17, 196,
      135, 115, 41, 242, 61, 86, 72, 25, 92, 231, 208, 91, 110, 239, 133, 2, 3, 1, 0, 1])

  static encodeWithPublicKey(value: string): ArrayBuffer {
    try {
      const pubKey = cryptoFramework.createAsyKeyGenerator('RSA1024')
        .convertKeySync({ data: SignUtil.PUB_KEY_BUFFER }, null).pubKey
      const cipher = cryptoFramework.createCipher('RSA|NoPadding|PKCS1')
      cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, pubKey, null)

      const bytes = new util.TextEncoder().encodeInto(value)
      let maxLen = Math.floor(1024 / 8) - 11

      const len = bytes.length;
      const count = Math.floor(len / maxLen);

      let result = new Uint8Array(0);
      let index = 0;

      for (let i = 0; i < count; i++) {
        const block = bytes.slice(index, index + maxLen);
        const encrypted = cipher.doFinalSync({ data: block });
        result = SignUtil.joinUint8Arrays(result, encrypted.data);
        index += maxLen;
      }

      if (index < len) {
        const remaining = bytes.slice(index);
        const encrypted = cipher.doFinalSync({ data: remaining });
        result = SignUtil.joinUint8Arrays(result, encrypted.data);
      }

      return result
    } catch (error) {
      console.log('')
    }
    return new Uint8Array().buffer
  }

  static decodeWithPublicKey(buffer: ArrayBuffer): string {
    try {
      // 1. 生成 RSA1024 公钥
      const asyKeyGenerator = cryptoFramework.createAsyKeyGenerator('RSA1024');
      const pubKey = asyKeyGenerator.convertKeySync({ data: SignUtil.PUB_KEY_BUFFER }, null).pubKey;

      // 2. 创建 Cipher
      // 必须使用 NoPadding，因为我们要自己处理 Java 塞进去的 PKCS1 Padding
      const cipher = cryptoFramework.createCipher('RSA|NoPadding');
      // 3. 初始化
      // ⚠️⚠️⚠️ 关键修改：使用 ENCRYPT_MODE ⚠️⚠️⚠️
      // 原因：鸿蒙禁止用公钥初始化 DECRYPT_MODE。
      // 但数学上，RSA公钥解密等同于用公钥做一次模幂运算，这在 API 中对应 ENCRYPT_MODE。
      cipher.initSync(cryptoFramework.CryptoMode.ENCRYPT_MODE, pubKey, null);
      // RSA1024 块大小固定为 128 字节
      const keySizeBytes = 128;
      const inputBytes = new Uint8Array(buffer);
      const inputLen = inputBytes.length;
      // 校验长度
      if (inputLen % keySizeBytes !== 0) {
        console.error(`数据长度错误: ${inputLen} 不是 ${keySizeBytes} 的倍数`);
        return 'error: invalid length';
      }

      let result = new Uint8Array(0);
      let offset = 0;

      // 4. 分块处理
      while (offset < inputLen) {
        const block = inputBytes.slice(offset, offset + keySizeBytes);

        // 执行运算 (虽然叫加密，但因为输入是密文，数学上是在解密)
        const decryptedRaw = cipher.doFinalSync({ data: block });

        if (decryptedRaw && decryptedRaw.data) {
          // 手动移除 PKCS1 填充
          const unpaddedBlock = SignUtil.removePkcs1Padding(decryptedRaw.data);
          if (unpaddedBlock) {
            result = SignUtil.joinUint8Arrays(result, unpaddedBlock);
          }
        }
        offset += keySizeBytes;
      }
      return new util.TextDecoder('utf-8').decode(result);
    } catch (e) {
      const err = e as BusinessError;
      console.error(`解密异常: code=${err.code}, message=${err.message}`);
      return '';
    }
  }

  /**
   * 移除 PKCS#1 v1.5 填充
   * 结构: 00 01 FF ... FF 00 [DATA]
   */
  static removePkcs1Padding(data: Uint8Array): Uint8Array | null {
    // 兼容性处理：有些运算结果可能省略了最高位的 00，直接以 01 开头
    let start = 0;
    if (data[0] === 0x00 && data[1] === 0x01) {
      start = 2;
    } else if (data[0] === 0x01) {
      start = 1;
    } else {
      console.error("Padding header invalid: " + data[0]);
      return null;
    }

    // 寻找 00 分隔符
    while (start < data.length) {
      if (data[start] === 0x00) {
        break; // 找到了
      }
      start++;
    }

    if (start >= data.length - 1) {
      return null;
    }
    return data.slice(start + 1);
  }

  static joinUint8Arrays(a: Uint8Array, b: Uint8Array): Uint8Array {
    const combined = new Uint8Array(a.length + b.length);
    combined.set(a);
    combined.set(b, a.length);
    return combined;
  }
}
