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

package joliex.websocket;

import jolie.runtime.*;
import jolie.runtime.embedding.RequestResponse;

import org.java_websocket.WebSocket;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.server.WebSocketServer;
import org.java_websocket.handshake.ServerHandshake;
import org.java_websocket.handshake.ClientHandshake;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

// @AndJarDeps( { "Java-WebSocket.jar", "slf4j-api.jar", "slf4j-simple.jar" } )
@AndJarDeps( "slf4j-simple.jar" )
public class WebSocketUtils extends JavaService {
	private class JolieWebSocketClient extends WebSocketClient {
		private final String id;
		private final Embedder embedder;
		private final Value correlationData;

		public JolieWebSocketClient( String id, URI serverUri, Embedder embedder, Map< String, String > headers,
			Value correlationData ) {
			super( serverUri, headers );
			this.id = id;
			this.embedder = embedder;
			this.correlationData = correlationData;
		}

		private Value buildNotificationValue() {
			Value v = Value.create();
			v.getFirstChild( "corrData" ).deepCopy( correlationData );
			v.setFirstChild( "id", id );
			return v;
		}

		@Override
		public void onOpen( ServerHandshake handshake ) {
			try {
				embedder.callOneWay( "onOpen", buildNotificationValue() );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

		@Override
		public void onClose( int code, String reason, boolean remote ) {
			try {
				Value v = buildNotificationValue();
				v.setFirstChild( "code", code );
				v.setFirstChild( "reason", reason );
				v.setFirstChild( "remote", remote );
				embedder.callOneWay( "onClose", v );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

		@Override
		public void onMessage( ByteBuffer message ) {
			throw new UnsupportedOperationException();
		}

		@Override
		public void onMessage( String message ) {
			try {
				Value v = buildNotificationValue();
				v.setFirstChild( "message", message );
				embedder.callOneWay( "onMessage", v );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

		@Override
		public void onError( Exception ex ) {
			try {
				Value v = buildNotificationValue();
				v.setFirstChild( "error", ex.getMessage() );
				embedder.callOneWay( "onError", v );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}
	}

	private class JolieWebSocketServer extends WebSocketServer {
		private final Embedder embedder;
		private final Value correlationData;

		public JolieWebSocketServer( String host, int port, Embedder embedder, Value correlationData ) {
			// TODO: add TLS
			super( new InetSocketAddress( host.isEmpty() ? "localhost" : host, port ) );
			this.embedder = embedder;
			this.correlationData = correlationData;
		}

		private Value buildNotificationValue() {
			Value v = Value.create();
			v.getFirstChild( "corrData" ).deepCopy( correlationData );
			return v;
		}

		@Override
		public void onStart() {
			try {
				embedder.callOneWay( "onStart", buildNotificationValue() );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

		@Override
		public void onOpen( WebSocket conn, ClientHandshake handshake ) {
			try {
				Value v = buildNotificationValue();
				v.setFirstChild( "id", conn.getRemoteSocketAddress().toString() );
				embedder.callOneWay( "onOpen", v );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

		@Override
		public void onClose( WebSocket conn, int code, String reason, boolean remote ) {
			try {
				Value v = buildNotificationValue();
				v.setFirstChild( "id", conn.getRemoteSocketAddress().toString() );
				v.setFirstChild( "code", code );
				v.setFirstChild( "reason", reason );
				v.setFirstChild( "remote", remote );
				embedder.callOneWay( "onClose", v );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

		@Override
		public void onMessage( WebSocket conn, ByteBuffer message ) {
			throw new UnsupportedOperationException();
		}

		@Override
		public void onMessage( WebSocket conn, String message ) {
			try {
				Value v = buildNotificationValue();
				v.setFirstChild( "id", conn.getRemoteSocketAddress().toString() );
				v.setFirstChild( "message", message );
				embedder.callOneWay( "onMessage", v );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

		@Override
		public void onError( WebSocket conn, Exception ex ) {
			try {
				Value v = buildNotificationValue();
				v.setFirstChild( "id", conn.getRemoteSocketAddress().toString() );
				v.setFirstChild( "error", ex.getMessage() );
				embedder.callOneWay( "onError", v );
			} catch( IOException e ) {
				interpreter().logWarning( e );
			}
		}

	}

	private final Map< String, JolieWebSocketClient > clients = new ConcurrentHashMap<>();
	private volatile JolieWebSocketServer server;

	@RequestResponse
	public void connect( Value request )
		throws FaultException {
		try {
			String id = request.getFirstChild( "id" ).strValue();
			Map< String, String > headers = new HashMap<>();
			if( request.hasChildren( "headers" ) ) {
				for( Map.Entry< String, ValueVector > entry : request.getFirstChild( "headers" ).children()
					.entrySet() ) {
					headers.put( entry.getKey(), entry.getValue().first().strValue() );
				}
			}
			final JolieWebSocketClient client =
				new JolieWebSocketClient( id, new URI( request.getFirstChild( "uri" ).strValue() ),
					getEmbedder(), headers, request.getFirstChild( "corrData" ) );
			clients.put( id, client );
			client.connect();
		} catch( URISyntaxException e ) {
			throw new FaultException( "URISyntaxException", e );
		}
	}

	@RequestResponse
	public void bind( Value request ) throws FaultException {
		final JolieWebSocketServer server =
			new JolieWebSocketServer( request.getFirstChild( "host" ).strValue(),
				request.getFirstChild( "port" ).intValue(), getEmbedder(), request.getFirstChild( "corrData" ) );
		server.setDaemon( true );
		server.start();
		this.server = server;
	}

	@RequestResponse
	public void send( Value request )
		throws FaultException {
		JolieWebSocketClient client = clients.get( request.getFirstChild( "id" ).strValue() );
		if( client != null ) {
			client.send( request.getFirstChild( "message" ).strValue() );
		} else {
			throw new FaultException( "NotFound" );
		}
	}

	@RequestResponse
	public void broadcast( Value request ) throws FaultException {
		if (server == null) {
			throw new FaultException( "NotFound" );
		}

		if ( !request.hasChildren( "ids" )) {
			server.broadcast( request.getFirstChild( "message" ).strValue() );
		} else {
			Collection< WebSocket > allConnections = server.getConnections(),
				filteredConnections = new ArrayList< WebSocket >();
			for ( Value id : request.getChildren( "ids" ) ) {
				boolean found = false;
				for ( WebSocket conn : allConnections ) {
					if ( conn.getRemoteSocketAddress().toString().equals( id.strValue() ) ) {
						filteredConnections.add( conn );
						found = true;
					}
				}
				if ( !found ) {
					throw new FaultException( "NotFound" );
				}
			}

			server.broadcast( request.getFirstChild( "message" ).strValue(), filteredConnections );
		}
	}

	public void close( Value request ) {
		JolieWebSocketClient client = clients.get( request.getFirstChild( "id" ).strValue() );
		if( client != null ) {
			client.close();
		}
	}

	@RequestResponse
	public void stop() {
		if( server != null ) {
			try {
				server.stop();
			} catch( InterruptedException e ) {
				interpreter().logWarning( e );
			}
		}
	}
}
