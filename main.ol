/*
 * Copyright (C) 2021 Fabrizio Montesi <famontesi@gmail.com>
 * Copyright (C) 2025 Matthias Wallnöfer <mdw@samba.org>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

/// A websocket identifier
type WID:string

type ConnectRequest {
	id:WID //< the id that should be assigned to the websocket
	uri:string //< the websocket URI to connect to
	ssl?:undefined //< consider the Jolie docs' section "Security with SSL"
	tcpNoDelay?:bool //< whether to disable the Nagle algorithm (default: false)
	corrData?:undefined //< correlation data for the notifications received from the utilities, if any
	headers?:undefined //< HTTP headers, if any
}

type BindRequest {
	host?:string //< the websocket host (per default "localhost")
	port:int //< the websocket port
	ssl?:undefined //< consider the Jolie docs' section "Security with SSL"
	tcpNoDelay?:bool //< whether to disable the Nagle algorithm (default: false)
	corrData?:undefined //< correlation data for the notifications received from the utilities, if any
}

type CloseRequest {
	id:WID //< The websocket id
}

type SendRequest {
	id:WID //< The websocket id
	message:string|raw //< The message
}

type BroadcastRequest {
	message:string|raw //< The message to broadcast
	ids[ 0, * ]:WID //< The ids of the websockets to broadcast to. If not specified, the message is broadcasted to all websockets
}

interface WebSocketUtilsInterface {
RequestResponse:
	/// Client: Opens a websocket connection. Returns the id of the created websocket handler.
	connect( ConnectRequest )( void ) throws URISyntaxException SSLError(string),
	/// Server: Starts a websocket server.
	bind( BindRequest )( void ) throws SSLError(string),
	/// Client: Sends a message over the specified websocket
	send( SendRequest )( void ) throws NotFound(void),
	/// Server: Broadcasts a message to all/specified websockets
	broadcast( BroadcastRequest )( void ) throws NotFound(void),
	/// Server: Stops a running websocket server
	stop( void )( void )
OneWay:
	/// Client: Closes a websocket connection
	close( CloseRequest )
}

type onStartMesg {
	corrData?:undefined
}

type OnOpenMesg {
	id:WID
	corrData?:undefined
}

type OnCloseMesg {
	id:WID
	corrData?:undefined
	code:int
	reason:string
	remote:bool
}

type OnMessageMesg {
	id:WID
	corrData?:undefined
	message:string|raw
}

type OnErrorMesg {
	id:WID
	corrData?:undefined
	error:string
}

interface WebSocketHandlerInterface {
OneWay:
	onStart( onStartMesg ),
	onOpen( OnOpenMesg ),
	onMessage( OnMessageMesg ),
	onClose( OnCloseMesg ),
	onError( OnErrorMesg )
}

service WebSocketUtils {
	inputPort Input {
		location: "local"
		interfaces: WebSocketUtilsInterface
	}

	foreign java {
		class: "joliex.websocket.WebSocketUtils"
	}
}

