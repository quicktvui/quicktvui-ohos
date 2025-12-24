/**
 * Use these variables when you tailor your ArkTS code. They must be of the const type.
 */
export const HAR_VERSION = '1.0.0';
export const BUILD_MODE_NAME = 'release';
export const DEBUG = false;
export const TARGET_NAME = 'default';
export const API_HOST = 'https://api.default.com';
export const ENABLE_LOG = true;
export const PACKAGE_NAME = 'com.test.package';

/**
 * BuildProfile Class is used only for compatibility purposes.
 */
export default class BuildProfile { 
	static readonly HAR_VERSION = HAR_VERSION;
	static readonly BUILD_MODE_NAME = BUILD_MODE_NAME;
	static readonly DEBUG = DEBUG;
	static readonly TARGET_NAME = TARGET_NAME;
	static readonly API_HOST = API_HOST;
	static readonly ENABLE_LOG = ENABLE_LOG;
	static readonly PACKAGE_NAME = PACKAGE_NAME;
}