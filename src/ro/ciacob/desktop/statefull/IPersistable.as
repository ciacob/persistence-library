package ro.ciacob.desktop.statefull {
	import ro.ciacob.desktop.signals.IObserver;

	public interface IPersistable extends IObserver {

		/**
		 * Populates this implementor's value from a simple Object, previously produced by a call to
		 * `toSource()` method.
		 *
		 * @param	Object
		 * 			A simple Object to set the implementor's current value from.
		 */
		function fromSource(source:Object):void;

		/**
		 * Returns the current value of this implementor. The exact format of the data thus retrieved
		 * is discretionary to each implementor.
		 */
		function getValue():*;

		/**
		 * Returns the key the Persistence library will use for storing this implementor's value in the
		 * cache, and retrieving it, thereafter.
		 *
		 * @return	String
		 * 			A key. Any string is valid, but is recommended to use manageable size strings.
		 *
		 * NOTE:
		 * You must use a unique key for each implementor, unless you want to have linked implementors,
		 * in which case you will reuse keys to define groups.
		 */
		function get key():String;

		/**
		 * Changes the current value of this implementor.
		 *
		 * @param	value
		 * 			The new value to set. If the value is not appropriate (e.g., it has an unsuported
		 * 			type/format), this implementor should silently discard it. The exact format of the
		 * 			data expected is discretionary to each implementor.
		 */
		function setValue(value:*):void;

		/**
		 * Stores this implementor's current value into a simple Object that is serializable by the
		 * Persistence library.
		 *
		 * NOTE:
		 * The resulting Object needs not be flatten, nor contain only primitive types. It can
		 * also contain nested simple Objects, to any level deep, and/or Arrays, which can contain
		 * other arrays or simple Objects, also to any level deep.
		 * It CANNOT contain custom types (this will cause a VerrifyError).
		 *
		 * @return	Object
		 * 			A simple Object representation of the implementor's current value.
		 */
		function toSource():Object;
	}
}
