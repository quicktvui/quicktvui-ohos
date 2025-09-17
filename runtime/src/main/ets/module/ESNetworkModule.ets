import {
  HippyEngineContext,
  HippyAny,
  HippyMap,
  HippyRecord,
  HippyArray,
  HippyModulePromise,
  HippyNativeModule,
  LogUtils
} from 'hippy';

import { BaseModule } from './BaseModule';
import { connection } from '@kit.NetworkKit';
import { AsyncCallback, BusinessError } from '@kit.BasicServicesKit';

/**
 * 自定义网络模块
 */
@HippyNativeModule({ name: "ESNetworkModule" })
export class ESNetworkModule extends BaseModule {
  public static readonly NAME: string = 'ESNetworkModule'
  conn: connection.NetConnection | null = null
  networkCallback: AsyncCallback<void> = (err: BusinessError, data: void) => {
    LogUtils.i('ESNetworkModule',
      'register networkCallback: err:' + err + ' data:' + data);
  }

  constructor(ctx: HippyEngineContext) {
    super(ctx)
  }

  initialize(): void {
    let netSpecifier: connection.NetSpecifier = {
      netCapabilities: {
        // 假设当前默认网络是WiFi，需要创建蜂窝网络连接，可指定网络类型为蜂窝网。
        bearerTypes: [
          connection.NetBearType.BEARER_CELLULAR,
          connection.NetBearType.BEARER_WIFI,
          connection.NetBearType.BEARER_ETHERNET
        ],
        // 指定网络能力为Internet。
        networkCap: [
          connection.NetCap.NET_CAPABILITY_INTERNET,
        ]
      },
    };
    // 指定超时时间为10s(默认值为0)。
    let timeout = 10 * 1000;
    // 创建NetConnection对象。
    this.conn = connection.createNetConnection(netSpecifier, timeout);
    // 订阅指定网络状态变化的通知。
    this.conn.register(this.networkCallback);
    // 订阅事件，如果当前指定网络可用，通过on_netAvailable通知用户。
    this.conn.on('netAvailable', ((data: connection.NetHandle) => {
      this.dispatchEvent("onConnectivityChanged", {})
    }));
    // 订阅事件，如果当前指定网络不可用，通过on_netUnavailable通知用户。
    this.conn.on('netUnavailable', ((data: void) => {
      this.dispatchEvent("onConnectivityChanged", {})
    }));
  }

  public call(method: string, params: Array<HippyAny>, promise: HippyModulePromise): HippyAny {
    switch (method) {
      //WIFI类型
      case 'getWifiInfo':
        this.getWifiNetworkInfoList().then(ret => {
          promise.resolve(ret);
        })
        break;
    //网络类型
      case 'getNetworkType':
        this.getDefaultNetworkType().then(ret => {
          promise.resolve(ret);
        })
        break;
    //所有默认网络信息
      case 'getActiveNetworkInfo':
        this.getDefaultNetworkInfo().then(ret => {
          promise.resolve(ret);
        })
        break;
    //所有注册网络
      case 'getNetworkInfoList': {
        this.getNetworkInfoList().then(ret => {
          promise.resolve(ret);
        })
        break;
      }
    //网络是否链接
      case 'isNetworkConnected': {
        try {
          const ret = this.isNetworkConnected()
          promise.resolve(ret)
        } catch (e) {
          let err = e as BusinessError;
          promise.reject(JSON.stringify(err))
        }
        break;
      }
      default:
        super.call(method, params, promise);
    }
    return null;
  }

  destroy(): void {
    if (this.conn != null) {
      // 当不使用该网络时，可以调用该对象的unregister()方法，取消订阅。
      this.conn.unregister(this.networkCallback);
    }
  }

  //-----------------------------------------------------------------------------

  async getWifiNetworkInfoList(): Promise<HippyMap> {
    try {
      const netList = await connection.getAllNets() ?? [];
      if (!netList) {
        return Promise.resolve(new Map());
      }
      const netSet: Set<connection.NetHandle> = new Set(netList);
      const netArray = Array.from(netSet);
      for (const netHandle of netArray) {
        try {
          const network: HippyMap = new Map()
          network.set("netId", netHandle.netId)
          const capabilities = await connection.getNetCapabilities(netHandle);
          network.set("capabilities", this.capabilitiesToHippyAny(capabilities))

          const types = this.bearerTypesToHippyAny(capabilities?.bearerTypes)
          let bearerTypesNum = Array.from(types);
          for (let item of bearerTypesNum) {
            if (item == 0) {
              // 蜂窝网络。
            } else if (item == 1) {
              // Wi-Fi网络。
              const properties = await connection.getConnectionProperties(netHandle);
              network.set("properties", this.propertiesToHippyAny(properties))
              return Promise.resolve(network)
            } else if (item == 3) {
              // 以太网网络。
            }
          }
        } catch (err) {
        }
      }
      return Promise.resolve(new Map())
    } catch (error) {
      return Promise.reject(error)
    }
  }

  /**
   * 默认网络类型
   * @returns
   */
  async getDefaultNetworkType(): Promise<HippyAny> {
    try {
      const defaultNetwork = await connection.getDefaultNet();
      if (!defaultNetwork) {
        return Promise.resolve(-1);
      }
      const network: HippyMap = new Map()
      network.set("netId", defaultNetwork.netId)
      const capabilities = await connection.getNetCapabilities(defaultNetwork);
      const bearerTypes = this.bearerTypesToHippyAny(capabilities?.bearerTypes)
      return Promise.resolve(bearerTypes[0])
    } catch (error) {
      return Promise.reject(error)
    }
  }

  /**
   * 获取默认网络的信息
   * @returns
   */
  async getDefaultNetworkInfo(): Promise<HippyMap> {
    try {
      const defaultNetwork = await connection.getDefaultNet();
      if (!defaultNetwork) {
        return Promise.resolve(new Map());
      }
      const network: HippyMap = new Map()
      network.set("netId", defaultNetwork.netId)
      const capabilities = await connection.getNetCapabilities(defaultNetwork);
      network.set("capabilities", this.capabilitiesToHippyAny(capabilities))
      const properties = await connection.getConnectionProperties(defaultNetwork);
      network.set("properties", this.propertiesToHippyAny(properties))
      return Promise.resolve(network)
    } catch (error) {
      return Promise.reject(error)
    }
  }

  /**
   * 获取所有注册网络的列表
   * @returns
   */
  async getNetworkInfoList(): Promise<Array<HippyMap>> {
    try {
      const netList = await connection.getAllNets() ?? [];
      if (!netList) {
        return Promise.resolve([]);
      }
      const netSet: Set<connection.NetHandle> = new Set(netList);
      const netArray = Array.from(netSet);
      const networkInfoList: Array<HippyMap> = []
      for (const netHandle of netArray) {
        try {
          const network: HippyMap = new Map()
          network.set("netId", netHandle.netId)
          const capabilities = await connection.getNetCapabilities(netHandle);
          network.set("capabilities", this.capabilitiesToHippyAny(capabilities))
          const properties = await connection.getConnectionProperties(netHandle);
          network.set("properties", this.propertiesToHippyAny(properties))
          networkInfoList.push(network)
        } catch (err) {
        }
      }
      return Promise.resolve(networkInfoList)
    } catch (error) {
      return Promise.reject(error)
    }
  }

  /**
   * 判断网络是否链接
   * @returns
   */
  isNetworkConnected(): boolean {
    let netHandle = connection.getDefaultNetSync();
    if (!netHandle || netHandle.netId === 0) {
      return false
    }
    let netCapabilities = connection.getNetCapabilitiesSync(netHandle);
    let cap = netCapabilities.networkCap || [];
    if (!cap.includes(connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY) &&
    cap.includes(connection.NetCap.NET_CAPABILITY_VALIDATED)) {
      // NET_CAPABILITY_CHECKING_CONNECTIVITY表示在进行连通性判断的过程中，当不处于连通性判断过程中，且networkCap数组中包含NET_CAPABILITY_VALIDATED表示网络连通性校验通过
      return true
    } else {
      return false
    }
  }

  //-------------------------------------------------------------------------
  capabilitiesToHippyAny(capabilities: connection.NetCapabilities): HippyMap {
    const map: HippyMap = new Map();
    map.set("linkUpBandwidthKbps", capabilities?.linkUpBandwidthKbps ?? -1)
    map.set("linkDownBandwidthKbps", capabilities?.linkDownBandwidthKbps ?? -1)
    map.set("networkCap", this.networkCapToHippyAny(capabilities?.networkCap))
    map.set("bearerTypes", this.bearerTypesToHippyAny(capabilities?.bearerTypes))
    return map;
  }

  networkCapToHippyAny(netCapList?: Array<connection.NetCap>): HippyArray {
    const result: HippyArray = [];
    if (netCapList && netCapList.length > 0) {
      for (const cap of netCapList) {
        result.push(cap); // 保留枚举的数值
      }
    }
    return result;
  }

  bearerTypesToHippyAny(netBearTypeList?: Array<connection.NetBearType>): HippyArray {
    const result: HippyArray = [];
    if (netBearTypeList && netBearTypeList.length > 0) {
      for (const netBearType of netBearTypeList) {
        result.push(netBearType); // 保留枚举的数值
      }
    }
    return result;
  }

  //-------------------------------------------------------------------------
  propertiesToHippyAny(connectionProperties: connection.ConnectionProperties): HippyMap {
    const map: HippyMap = new Map();
    map.set("interfaceName", connectionProperties.interfaceName)
    map.set("domains", connectionProperties.domains)
    map.set("mtu", connectionProperties.mtu)
    map.set("routes", this.routesToHippyAny(connectionProperties.routes))
    map.set("dnses", connectionProperties.dnses.map((d) => this.netAddressToHippyAny(d)))
    map.set("linkAddresses",
      connectionProperties.linkAddresses.map((d) => this.linkAddressToHippyAny(d)))
    return map;
  }

  routesToHippyAny(routes: Array<connection.RouteInfo>): HippyArray {
    const result: HippyArray = [];
    if (routes && routes.length > 0) {
      for (const route of routes) {
        const map: HippyMap = new Map();
        map.set("interface", route.interface)
        map.set("destination", this.linkAddressToHippyAny(route.destination))
        map.set("hasGateway", route.hasGateway)
        map.set("isDefaultRoute", route.isDefaultRoute)
        map.set("gateway", this.netAddressToHippyAny(route.gateway))
      }
    }
    return result;
  }

  linkAddressToHippyAny(linkAddress: connection.LinkAddress): HippyMap {
    const map: HippyMap = new Map();
    map.set("address", this.netAddressToHippyAny(linkAddress.address))
    map.set("prefixLength", linkAddress.prefixLength)
    return map;
  }

  netAddressToHippyAny(netAddress: connection.NetAddress): HippyRecord {
    const result: HippyRecord = {
      "address": netAddress.address,
      "family": netAddress.family ?? -1,
      "port": netAddress.port ?? -1,
    };
    return result;
  }
}
