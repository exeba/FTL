/* Pi-hole: A black hole for Internet advertisements
*  (c) 2020 Pi-hole, LLC (https://pi-hole.net)
*  Network-wide ad blocking via your own hardware.
*
*  FTL Engine
*  Pi-hole syscall implementation for fallocate
*
*  This file is copyright under the latest version of the EUPL.
*  Please see LICENSE file for your rights under this license. */

#include "../FTL.h"
//#include "syscalls.h" is implicitly done in FTL.h
#include "../log.h"
#include <fcntl.h>

// off_t is automatically set as off64_t when this is a 64bit system
int FTLfallocate(const int fd, const off_t offset, const off_t len, const char *file, const char *func, const int line)
{
	if (offset != 0)
	{
		logg("WARN: Cannot set offset on ftruncate() in %s() (%s:%i)",
		     func, file, line);
		errno = EINVAL;

		return errno;
	}

	do
	{
		ftruncate(fd, len);
	}
	// Try again if the last ftruncate() call failed due to an
	// interruption by an incoming signal
	while(errno == EINTR);

	// Final error checking (may have failed for some other reason then an
	// EINTR = interrupted system call)
	if(errno > 0)
		logg("WARN: Could not fallocate() in %s() (%s:%i): %s",
		     func, file, line, strerror(errno));

	return errno;
}
