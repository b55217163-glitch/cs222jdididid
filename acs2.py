# acs2_lite.py — без numpy
import pymem
import pymem.process
import time
import math
import struct

PROCESS_NAME = "cs2.exe"
CLIENT_DLL   = "client.dll"

dwEntityList            = 0x2711598
dwLocalPlayerPawn       = 0x255C3C8
dwViewAngles            = 0x2572AE8

m_hPlayerPawn      = 0x8FC
m_iHealth          = 0x34C
m_lifeState        = 0x354
m_iTeamNum         = 0x3E7
m_pGameSceneNode   = 0x330
m_modelState       = 0x190
m_vecAbsOrigin     = 0xD0
m_vOldOrigin       = 0x15A0
BONE_MATRIX        = 0x80
BONE_HEAD          = 6

FOV_LIMIT  = 6.0
TEAM_CHECK = True

def normalize(pitch, yaw):
    if pitch > 89.0:  pitch = 89.0
    if pitch < -89.0: pitch = -89.0
    while yaw > 180.0: yaw -= 360.0
    while yaw < -180.0: yaw += 360.0
    return pitch, yaw

def calc_angle(src, dst):
    dx = dst[0] - src[0]
    dy = dst[1] - src[1]
    dz = dst[2] - src[2]
    hyp = math.sqrt(dx*dx + dy*dy)
    pitch = -math.degrees(math.atan2(dz, hyp))
    yaw   =  math.degrees(math.atan2(dy, dx))
    return normalize(pitch, yaw)

def get_fov(view, aim):
    dp = abs(view[0] - aim[0])
    dy = abs(view[1] - aim[1])
    if dy > 180: dy = 360 - dy
    return math.sqrt(dp*dp + dy*dy)

class CS2:
    def __init__(self):
        self.pm = pymem.Pymem(PROCESS_NAME)
        self.client = pymem.process.module_from_name(self.pm.process_handle, CLIENT_DLL).lpBaseOfDll
        print(f"[+] base: {hex(self.client)}")

    def read_i32(self, a): return self.pm.read_int(a)
    def read_u64(self, a): return self.pm.read_ulonglong(a)
    def read_f32(self, a): return self.pm.read_float(a)
    def read_vec3(self, a):
        return list(struct.unpack("fff", self.pm.read_bytes(a, 12)))

    def write_angles(self, pitch, yaw):
        a = self.client + dwViewAngles
        self.pm.write_float(a, float(pitch))
        self.pm.write_float(a + 4, float(yaw))

    def get_local_pawn(self):
        return self.read_u64(self.client + dwLocalPlayerPawn)

    def get_origin(self, pawn):
        node = self.read_u64(pawn + m_pGameSceneNode)
        if node:
            return self.read_vec3(node + m_vecAbsOrigin)
        return self.read_vec3(pawn + m_vOldOrigin)

    def get_bone_pos(self, pawn, bone=BONE_HEAD):
        node = self.read_u64(pawn + m_pGameSceneNode)
        if not node: return None
        arr = self.read_u64(node + m_modelState + BONE_MATRIX)
        if not arr: return None
        return self.read_vec3(arr + bone * 32)

    def get_entity_pawn(self, i):
        try:
            el = self.read_u64(self.client + dwEntityList)
            if not el: return 0
            le = self.read_u64(el + 0x8 * ((i & 0x7FFF) >> 9) + 0x10)
            if not le: return 0
            ctrl = self.read_u64(le + 0x78 * (i & 0x1FF))
            if not ctrl: return 0
            h = self.read_i32(ctrl + m_hPlayerPawn)
            if not h or h == -1: return 0
            le2 = self.read_u64(el + 0x8 * ((h & 0x7FFF) >> 9) + 0x10)
            if not le2: return 0
            return self.read_u64(le2 + 0x78 * (h & 0x1FF))
        except:
            return 0

def find_best(cs, local, view, origin):
    best_fov = FOV_LIMIT
    best = None
    team = cs.read_i32(local + m_iTeamNum)
    for i in range(1, 64):
        p = cs.get_entity_pawn(i)
        if not p or p == local: continue
        if cs.read_i32(p + m_lifeState) != 0: continue
        if cs.read_i32(p + m_iHealth) <= 0: continue
        if TEAM_CHECK and cs.read_i32(p + m_iTeamNum) == team: continue
        head = cs.get_bone_pos(p)
        if not head: continue
        ang = calc_angle(origin, head)
        fov = get_fov(view, ang)
        if fov < best_fov:
            best_fov = fov
            best = ang
    return best

def main():
    print("[*] CS2 Silent Aim lite")
    try:
        cs = CS2()
    except Exception as e:
        print(f"[!] {e}")
        input("Enter...")
        return
    print("[+] Running...")
    while True:
        try:
            local = cs.get_local_pawn()
            if not local:
                time.sleep(0.01)
                continue
            origin = cs.get_origin(local)
            if not origin: continue
            va = cs.client + dwViewAngles
            view = [cs.read_f32(va), cs.read_f32(va+4)]
            t = find_best(cs, local, view, origin)
            if t:
                cs.write_angles(t[0], t[1])
            time.sleep(0.001)
        except KeyboardInterrupt:
            break
        except:
            time.sleep(0.02)

if __name__ == "__main__":
    main()
