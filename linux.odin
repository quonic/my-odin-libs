package main

import "core:fmt"
import "core:os"
import "core:sys/linux"
import "core:sys/posix"

check_user_in_group :: proc(group_name: string) -> bool {
	// Resolve the group name to a gid via the group database (getgrnam wraps /etc/group + NSS)
	group_name_cstr := fmt.ctprint(group_name)
	group := posix.getgrnam(group_name_cstr)
	if group == nil {
		return false
	}
	target_gid := linux.Gid(group.gr_gid)

	// The primary gid isn't included in getgroups(), so check it separately
	if linux.Gid(os.get_gid()) == target_gid {
		return true
	}

	// getgroups with an empty slice returns the number of supplementary groups
	count, _ := linux.getgroups(nil)
	if count <= 0 {
		return false
	}

	gids := make([]linux.Gid, count)
	defer delete(gids)

	n, errno := linux.getgroups(gids)
	if errno != .NONE {
		return false
	}

	for gid in gids[:n] {
		if gid == target_gid {
			return true
		}
	}
	return false
}
