package ro.ciacob.desktop.statefull {
	import flash.events.IEventDispatcher;

	/**
	 * Provides a generic persistence solution for a desktop application built using AIR.
	 *
	 * @param	uid
	 * 			A unique id, that ensures unique access to a disc resource. If you attempt to
	 * 			instantiate two Persistences with the same uid, an error will be thrown. This
	 * 			protection ensures that no two Persistences will write to the same cache file.
	 * 			It is recommended that you use controlled, static UIDs rather than randomly
	 * 			generated ones.
	 *
	 * @param	storagePath
	 * 			Optional. A path on disk where to establish a cache to write to / read form.
	 * 			If omitted defaults to user application storage directory (the actual path usually
	 * 			employs "Application Settings" and the user name on all Windows versions).
	 *
	 * 			If you do provide a storage path, make sure it is either:
	 * 			a) a fully qualified folder path, in canonical form on the host operating system, or
	 * 			b) a fully qualified URL pointing to a folder, respecting the AIR specifications for file URLs.
	 * 	@see flash.filesystem.File
	 */
	public interface IPersistence extends IEventDispatcher {

		/**
		 * Flag indicating whether cache file existed when Persistence were previously initialized (false) or
		 * the file has just been created for the first time (true);
		 *
		 * @return	Whether cache file existed when Persistence was initialized (false) or the file
		 * 			has just been created for the first time (true);
		 */
		function get isFirstRun():Boolean;

		/**
		 * Stores to, or retrieves from, or both, a value to/from a disk cache. The action taken care is
		 * determined by the method signature employed (the number, type and order of arguments the method receives).
		 *
		 * @param	params
		 * 			The method recognizes the following signatures (there is no method overloading
		 * 			in AS3, this is as close as we can get):
		 *
		 * 			1. Persistence.persistence (element : IPersistable) : void;
		 * 			2. Persistence.persistence (name : String, value : *) : void;
		 * 			3. Persistence.persistence (name : String) : *;
		 *
		 * 			1. If the method receives a lone argument of the type IPersistable, it will (attempt to) set (write)
		 * 			   its value from cache when initially called, then will hook to its CHANGE event and will get (read)
		 * 			   its value into cache on every modification.
		 * 			2. If the method receives two arguments, first a string and the second any other value, it will
		 * 			   store the value in the cache using the given string as key.
		 * 			3. If the method receives a lone argument of the type String, it will look up the given string as a
		 * 			   key in the cache and return the value, which may be of any type.
		 *
		 * @throw	VerifyError
		 * 			Thrown if the value set to be cached failes the serialize/deserialize test. In order to prevent data corruption,
		 * 			each value, after being serialized for storage, is deserialized back, and the result compared with the original
		 * 			value. If the equality test fails, this error is thrown.
		 *
		 * 			If you encounter this exception, it means that you must implement a serialize / deserialize routine yourself in
		 * 			your object being cached, rather than rely on the library's inner mechanisms.
		 */
		function persistence(... params):*;
	}
}
