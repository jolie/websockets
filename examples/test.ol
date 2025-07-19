/*
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

from runtime import Runtime
from .localServer import LocalServer
from .localSslServer import LocalSslServer
from time import Time //FIXME: remove sleep()

service Main {
	embed Runtime as runtime
	embed LocalServer
	embed LocalSslServer
	embed Time as time //FIXME: remove sleep()

	define __embed_service {
		loadEmbeddedService@runtime( { .filepath = __service + ".ol" } )()
	}

	main {
		__service = "localClient"
		__embed_service
		sleep@time( 1000 )() //FIXME: remove sleep()
		__service = "localSslClient"
		__embed_service
		sleep@time( 1000 )() //FIXME: remove sleep()
	}
}