package gessie.util;

import haxe.ds.IntMap;


@:noCompletion typedef EmitHandler = Dynamic->Void;
@:noCompletion typedef HandlerList = Array<EmitHandler>;

@:noCompletion private typedef EmitNode<T> = { event : T, handler:EmitHandler #if debug, ?pos:haxe.PosInfos #end }


/** A simple event emitter, used as a base class for systems that want to handle direct connections to named events */

// @:generic
class Emitter<ET:Int> {

    @:noCompletion public var bindings : IntMap<HandlerList>;

        //store connections loosely, to find connected locations
    var connected : List< EmitNode<ET> >;
        //store the items to remove
    var _to_remove : List< EmitNode<ET> >;

        /** create a new emitter instance, for binding functions easily to named events. similar to `Events` */
    public function new() {

        _to_remove = new List();
        connected = new List();

        bindings = new IntMap<HandlerList>();

    } //new

        /** Emit a named event */
    @:noCompletion public function emit<T>( event:ET, ?data:T #if debug, ?pos:haxe.PosInfos #end ) {

        _check();

        var list = bindings.get(event);
        if(list != null && list.length > 0) {
            for(handler in list) {
                handler(data);
            }
        }

            //needed because handlers
            //might disconnect listeners
        _check();

    } //emit

        /** connect a named event to a handler */
    @:noCompletion public function on<T>(event:ET, handler: T->Void #if debug, ?pos:haxe.PosInfos #end ) {

        _check();
		
        if(!bindings.exists(event)) {

            bindings.set(event, [handler]);
            connected.push({ handler:handler, event:event #if debug, pos:pos #end });

        } else {
            var list = bindings.get(event);
            if(list.indexOf(handler) == -1) {
                list.push(handler);
                connected.push({ handler:handler, event:event #if debug, pos:pos #end });
            }
        }

    } //on

        /** disconnect a named event and handler. returns true on success, or false if event or handler not found */
    @:noCompletion public function off<T>(event:ET, handler: T->Void #if debug, ?pos:haxe.PosInfos #end ) : Bool {

        _check();

        var success = false;

        if(bindings.exists(event)) {

            _to_remove.push({ event:event, handler:handler });

            for(_info in connected) {
                if(_info.event == event && Reflect.compareMethods(_info.handler, handler)) {
                    connected.remove(_info);
                }
            }

                //debateable :p
            success = true;

        } //if exists

        return success;

    } //off

    @:noCompletion public function connections( handler:EmitHandler ) {

        var list : Array<EmitNode<ET>> = [];

        for(_info in connected) {
            if(_info.handler == handler) {
                list.push(_info);
            }
        }

        return list;

    } //connections

    var _checking = false;

    function _check() {

        if(_checking) {
            return;
        }

        _checking = true;

        if(_to_remove.length > 0) {

            for(_node in _to_remove) {

                var list = bindings.get(_node.event);
                list.remove( _node.handler );

                    //clear the event list if there are no bindings
                if(list.length == 0) {
                    bindings.remove(_node.event);
                }

            } //each node

            _to_remove = null;
            _to_remove = new List();

        } //_to_remove length > 0

        _checking = false;

    } //_check

} //Emitter