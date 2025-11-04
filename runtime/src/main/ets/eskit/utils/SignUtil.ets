import cryptoFramework from '@ohos.security.cryptoFramework';
import util from '@ohos.util';
import cert from '@ohos.security.cert';

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

  /**
   * @throws
   */
  static encodeWithPublicKey2(value: string) {
    const pubKey = cryptoFramework.createAsyKeyGenerator('RSA')
      .convertKeySync({ data: SignUtil.PUB_KEY_BUFFER }, null).pubKey
    const cipher = cryptoFramework.createCipher('RSA/None/PKCS1Padding');
  }

  static joinUint8Arrays(a: Uint8Array, b: Uint8Array): Uint8Array {
    const combined = new Uint8Array(a.length + b.length);
    combined.set(a);
    combined.set(b, a.length);
    return combined;
  }

  // static decodeWithPublicKey(value: ArrayBuffer): string{
  //
  // }

}
