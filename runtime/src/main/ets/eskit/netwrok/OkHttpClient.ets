import http from "@ohos.net.http";

export class OkHttpClient {
  private clientOptions: OkHttpClientOptions

  constructor(options: OkHttpClientOptions = {
    connectTimeout: 10_000,
    readTimeout: 10_000,
    interceptors: []
  }) {
    this.clientOptions = options
  }

  async get(request: Request) {
    this.execute(http.RequestMethod.GET, request)
  }

  private async execute(method: http.RequestMethod, request: Request) {

    const interceptors = new Array<Interceptor>()
    interceptors.push(...this.clientOptions.interceptors)
    interceptors.push(new CallServerInterceptor())

    const chain = new ChainImpl(0, method, interceptors, request)
    chain.process(request)

    // const interceptors = this.clientOptions.interceptors
    // for (let i = 0; i < interceptors.length; i++) {
    //   interceptors[i].intercept(chain)
    // }

  }
}

export interface OkHttpClientOptions {
  connectTimeout: number
  readTimeout: number
  interceptors: Array<Interceptor>
}

export interface Request {
  url: string,
  data?: string | Object | ArrayBuffer;
  header?: Object
}

export interface Response {
  code: number
  message: string
  data: string | Object | ArrayBuffer
}

export interface Interceptor {
  intercept(chain: Chain): void;
}

export interface Chain {
  getRequest(): Request

  process(request: Request): Response
}

class ChainImpl implements Chain {
  private index: number;
  private method: http.RequestMethod
  private interceptors: Array<Interceptor>
  private request: Request

  constructor(index: number, method: http.RequestMethod, interceptors: Array<Interceptor>, request: Request) {
    this.index = index
    this.method = method
    this.interceptors = interceptors
    this.request = request
    // this.httpRequest = http.createHttp()
  }

  getRequest(): Request {
    return this.request
  }

  process(request: Request): Response {
    // if(this.index >= this.interceptors.length)
    return {
      code: 200,
      message: "",
      data: ""
    }
  }
}

class CallServerInterceptor implements Interceptor {
  intercept(chain: Chain): void {
    // return await new Promise<Response>((resolve, reject) => {
    //   this.httpRequest.request(
    //     request.url,
    //     {
    //       method: this.method,
    //       extraData: request.data,
    //       header: request.header
    //     },
    //     (error: BusinessError, response: http.HttpResponse) => {
    //       if (error) {
    //         reject(error)
    //       } else {
    //         resolve({})
    //       }
    //     }
    //   )
    // })
  }
}

export interface ResponseData<T> {
  code: number
  data: T
  msg: string
}