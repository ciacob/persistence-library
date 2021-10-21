package ro.ciacob.desktop.statefull {
	import avmplus.getQualifiedClassName;
	
	import flash.events.ErrorEvent;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	import flash.net.registerClassAlias;
	import flash.utils.ByteArray;
	import flash.utils.getDefinitionByName;
	
	import mx.utils.ObjectUtil;
	
	import ro.ciacob.desktop.data.constants.DataKeys;
	import ro.ciacob.desktop.io.AbstractDiskReader;
	import ro.ciacob.desktop.io.AbstractDiskWritter;
	import ro.ciacob.desktop.io.ObjectDiskReader;
	import ro.ciacob.desktop.io.ObjectDiskWritter;
	import ro.ciacob.desktop.io.RawDiskReader;
	import ro.ciacob.desktop.io.RawDiskWritter;
	import ro.ciacob.utils.Descriptor;

	public class Persistence extends EventDispatcher implements IPersistence {

		public static const PERSISTENCE_ENGINE_IDDLE:String = 'persistenceEngineIddle';
		
		private static const ARGUMENT_COUNT_MISMATCH:int = 1063;
		private static const OBJECT_TYPE:String = 'Object';
		private static const UNIQUE_IDS:Array = [];

		public function Persistence(uid:String, storagePath:String = null) {
			if (uid == null) {
				throw(new Error('\nClass Persistence - you must supply an unique id (uid) in order to\ncreate an instance of a Persistence class.\n'));
			}
			if (UNIQUE_IDS.indexOf(uid) !== -1) {
				throw(new Error('\nClass Persistence - the unique id `' + uid + '` is already used.\nPlease choose a unique id.\n'));
			}
			UNIQUE_IDS.push(uid);
			_uid = uid;
			if (storagePath == null) {
				storagePath = File.applicationStorageDirectory.nativePath;
			}
			_storagePath = storagePath;
			_cacheFileName = Descriptor.read('id').replace(/\./g, '-').concat('-persistence', '-', _uid);
			_cacheFile = new File(storagePath).resolvePath(_cacheFileName);
			_discReader = new ObjectDiskReader;
			_discWriter = new ObjectDiskWritter;
			_discWriter.addEventListener(ErrorEvent.ERROR, _onWriterError);
			if (_cacheFile.exists) {
				_cache = _discReader.readContent(_cacheFile);
				_cache = _reopenWithProperTyping(_cache, _cacheFile);
			} else {
				_isFirstRun = true;
				_cache = {};
				_discWriter.write(_cache, _cacheFile);
			}
		}

		private var _cache:Object;
		private var _cacheFile:File;
		private var _cacheFileName:String;
		private var _discReader:ObjectDiskReader;
		private var _discWriter:ObjectDiskWritter;
		private var _isFirstRun:Boolean;
		private var _storagePath:String;
		private var _uid:String;

		public function get isFirstRun():Boolean {
			return _isFirstRun;
		}

		public function persistence(... params):* {
			if (params.length == 1) {
				if (params[0] is IPersistable) {
					_persist_single_IPersistable(params[0] as IPersistable);
				} else if (params[0] is String) {
					return _retrieve_value_for_key(params[0] as String);
				} else {
					throw(new ArgumentError('\nClass Persistence - method `persist` was called with an unsupported\nlone argument type. Please consult documentation.\n'));
				}
			} else if (params.length == 2) {
				if (params[0] is String) {
					_store_value_for_key(params[0] as String, params[1]);
				} else {
					throw(new ArgumentError('\nClass Persistence - method `persist` was called with an unsupported\nfirst argument type. Please consult documentation.\n'));
				}
			} else {
				throw(new ArgumentError('\nClass Persistence - method `persist` was called with an unsupported\nnumber of arguments. Please consult documentation.\n'));
			}
		}

		private function _assertProperSerialization(original:*, key:String):void {
			var serialized:ByteArray = ObjectDiskWritter.toByteArray(original);
			var keyStoringType:String = _createKeyForStoringType(key);
			if (keyStoringType in _cache) {
				var maintainedType:String = _cache[keyStoringType];
				registerClassAlias(keyStoringType, Class(getDefinitionByName(maintainedType)));
			}
			var argCountMismatch:ArgumentError;
			try {
				var deserialized:* = ObjectDiskReader.fromByteArray(serialized);
				if (getQualifiedClassName(deserialized) == getQualifiedClassName(original)) {
					if (original is Object) {
						if (ObjectUtil.compare(deserialized, original) == 0) {
							return;
						}
					}
				}
			} catch (error:ArgumentError) {
				if (error.errorID == ARGUMENT_COUNT_MISMATCH) {
					argCountMismatch = error;
				}
			}
			var message:String = '\nClass Persistence - value corresponding to key `' + key + '` could not be\nserialized properly. Please provide custom serialization /\ndeserialization for this value.';
			if (argCountMismatch != null) {
				message = message.concat('\nThis most likely happens because the class you attempt to\nserialize expects arguments in its constructor AND it does not\nimplement the IExternalizable interface.');
			}
			message = message.concat('\n');
			throw(new VerifyError(message));
		}

		private function _createKeyForStoringType(baseKey:String):String {
			return baseKey.concat('-', _uid, '-type');
		}
		
		private function _onWriterError (event : Event) : void {
			dispatchEvent(event);
		}

		private function _persist_single_IPersistable(persistable:IPersistable):void {
			if (persistable.key in _cache) {
				persistable.fromSource(_cache[persistable.key]);
			}
			var callback : Function = function (... args) : void {
				var key : String = persistable.key;
				var value : Object = persistable.toSource();
				_store_value_for_key(key, value);
			}
			persistable.observe('change', callback);
		}

		private function _reopenWithProperTyping(cache:Object, cacheFile:File):Object {
			// We cannot properly load serialized custom types in one go, since information regarding their
			// type is packed in the same container as they are, the cache itself. 
			//
			// Therefore, loading data in the cache is done twice: first, to have access to all class aliases 
			// we must register; at this stage, all non-primitives in the cache were loaded as simple Objects,
			// but we'll discard them anyway. Then, we register the needed class aliases and load everything 
			// once more; at this stage, all custom types will properly retain their type.
			var classAliases:Object = {};
			for (var key:String in cache) {
				var testTypeKey:String = _createKeyForStoringType(key);
				if (testTypeKey in cache) {
					classAliases[testTypeKey] = cache[testTypeKey];
				}
			}
			cache = null;
			for (var classAlias:String in classAliases) {
				registerClassAlias(classAlias, Class(getDefinitionByName(classAliases[classAlias])));
			}
			classAliases = null;
			var rawReader:RawDiskReader = new RawDiskReader;
			var src:ByteArray = ByteArray(rawReader.readContent(cacheFile));
			cache = ObjectDiskReader.fromByteArray(src);
			return cache;
		}

		private function _retrieve_value_for_key(key:String):* {
			return _cache[key];
		}

		private function _store_value_for_key(key:String, value:*):void {
			_cache[key] = value;
			var mustMaintainType:Boolean = false;
			var valueIsPrimitive:Boolean = (value is Number || value is int || value is uint || value is Boolean || value is
				String);
			if (!valueIsPrimitive) {
				var typeOfValue:String = getQualifiedClassName(value);
				if (typeOfValue != OBJECT_TYPE) {
					mustMaintainType = true;
					var additionalKey:String = _createKeyForStoringType(key);
					_cache[additionalKey] = typeOfValue;
					registerClassAlias(additionalKey, Class(getDefinitionByName(typeOfValue)));
				}
				_assertProperSerialization(value, key);
			}
			_discWriter.write(_cache, _cacheFile);
			if (!mustMaintainType) {
				// This deals with the unlikely, but still possible, situation where a key previously holding
				// a custom type instance was recycled to hold a primitive or a simple Object or Array. Neither
				// of these need their type persisted, so we should cleanup the old `[key]-[uid]-type` key
				// to reclaim storage space.
				delete _cache[_createKeyForStoringType(key)];
			}
		}
	}
}
