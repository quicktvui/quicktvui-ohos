/**
 * Use these variables when you tailor your ArkTS code. They must be of the const type.
 */
export const HAR_VERSION = '1.0.0';
export const BUILD_MODE_NAME = 'debug';
export const DEBUG = true;
export const TARGET_NAME = 'default';
export const APP_ENTRY = '';
export const APP_ID = 'cn.openharmony.app.center';
export const BUNDLE_URI = 'assets:///vue/app_center';
export const PARAMS = '';

/**
 * BuildProfile Class is used only for compatibility purposes.
 */
export default class BuildProfile { 
	static readonly HAR_VERSION = HAR_VERSION;
	static readonly BUILD_MODE_NAME = BUILD_MODE_NAME;
	static readonly DEBUG = DEBUG;
	static readonly TARGET_NAME = TARGET_NAME;
	static readonly APP_ENTRY = APP_ENTRY;
	static readonly APP_ID = APP_ID;
	static readonly BUNDLE_URI = BUNDLE_URI;
	static readonly PARAMS = PARAMS;
}