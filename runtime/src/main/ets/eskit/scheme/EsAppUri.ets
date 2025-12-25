export interface EsAppUri {
  scheme: string
  host: string
  path: string
  params: Record<string, string>
}

export function parseEsAppUri(uri: string): EsAppUri {
  // scheme
  const schemeEnd = uri.indexOf('://')
  const scheme = uri.substring(0, schemeEnd)

  const rest = uri.substring(schemeEnd + 3) // action/start?xxx

  // host
  const firstSlash = rest.indexOf('/')
  const host = firstSlash === -1 ? rest : rest.substring(0, firstSlash)

  // path + query
  const pathAndQuery = firstSlash === -1 ? '' : rest.substring(firstSlash)
  const GeneratedDestructArray_1 = pathAndQuery.split('?')
  const path = GeneratedDestructArray_1[0];
  const query = GeneratedDestructArray_1[1];

  const params: Record<string, string> = {}
  if (query) {
    query.split('&').forEach(pair => {
      const GeneratedDestructArray_2 = pair.split('=')
      const key = GeneratedDestructArray_2[0];
      const value = GeneratedDestructArray_2[1];
      if (key) {
        params[key] = decodeURIComponent(value ?? '')
      }
    })
  }

  return {
    scheme,
    host,
    path,
    params
  }
}