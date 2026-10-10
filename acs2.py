# cs2_silent_aim.py
# External Silent Aim (closest to crosshair) — research / offline use
# Python 3.10+ | pymem | numpy
# Offsets: \~9 Oct 2026 (build \~14190)

import pymem
import pymem.process
import numpy as np
import time
import math
import struct

# ================== OFFSETS (актуальные) ==================
PROCESS_NAME = "cs2.exe"
CLIENT_DLL   = "client.dll"

dwEntityList            = 0x2711598
dwLocalPlayerPawn       = 0x255C3C8
dwLocalPlayerController = 0x25338A8
dwViewAngles            = 0x2572AE8
dwViewMatrix            = 0x2561CD0

# netvars
m_hPlayerPawn      = 0x8FC
m_iHealth          = 0x34C
m_lifeState        = 0x354
m_iTeamNum         = 0x3E7
m_pGameSceneNode   = 0x330
m_modelState       = 0x190
m_vecAbsOrigin     = 0xD0          # CGameSceneNode
m_vOldOrigin       = 0x15A0        # fallback position
m_angEyeAngles     = 0x3600        # approx, may vary
BONE_MATRIX        = 0x80          # inside modelState
BONE_HEAD          = 6

# ================== SETTINGS ==================
FOV_LIMIT   = 6.0      # градусов — насколько близко к прицелу
TEAM_CHECK  = True
HEAD_ONLY   = True

# ================== MATH ==================
def normalize(pitch, yaw):
    if pitch > 89.0:  pitch = 89.0
    if pitch < -89.0: pitch = -89.0
    while yaw > 180.0: yaw -= 360.0
    while yaw < -180.0: yaw += 360.0
    return pitch, yaw

def calc_angle(src, dst):
    delta = np.array(dst, dtype=float) - np.array(src, dtype=float)
    hyp = math.sqrt(delta[0]**2 + delta[1]**2)
    pitch = -math.degrees(math.atan2(delta[2], hyp))
    yaw   =  math.degrees(math.atan2(delta[1], delta[0]))
    return normalize(pitch, yaw)

def get_fov(view, aim):
    dp = abs(view[0] - aim[0])
    dy = abs(view[1] - aim[1])
    if dy > 180:
        dy = 360 - dy
    return math.sqrt(dp*dp + dy*dy)

# ================== MEMORY ==================
class CS2:
    def __init__(self):
        self.pm = pymem.Pymem(PROCESS_NAME)
        self.client = pymem.process.module_from_name(
            self.pm.process_handle, CLIENT_DLL
        ).lpBaseOfDll
        print(f"[+] client.dll base: {hex(self.client)}")

    def read_i32(self, addr):
        return self.pm.read_int(addr)

    def read_u64(self, addr):
        return self.pm.read_ulonglong(addr)

    def read_f32(self, addr):
        return self.pm.read_float(addr)

    def read_vec3(self, addr):
        data = self.pm.read_bytes(addr, 12)
        return list(struct.unpack("fff", data))

    def write_angles(self, pitch, yaw):
        addr = self.client + dwViewAngles
        self.pm.write_float(addr, float(pitch))
        self.pm.write_float(addr + 4, float(yaw))

    def get_local_pawn(self):
        return self.read_u64(self.client + dwLocalPlayerPawn)

    def get_origin(self, pawn):
        # предпочтительно через GameSceneNode
        node = self.read_u64(pawn + m_pGameSceneNode)
        if node:
            return self.read_vec3(node + m_vecAbsOrigin)
        # fallback
        return self.read_vec3(pawn + m_vOldOrigin)

    def get_bone_pos(self, pawn, bone_id=BONE_HEAD):
        node = self.read_u64(pawn + m_pGameSceneNode)
        if not node:
            return None
        # CSkeletonInstance -> m_modelState
        bone_array = self.read_u64(node + m_modelState + BONE_MATRIX)
        if not bone_array:
            return None
        # каждая кость = 32 байта
        return self.read_vec3(bone_array + bone_id * 32)

    def get_entity_pawn(self, index):
        """Правильный обход EntityList CS2"""
        try:
            ent_list = self.read_u64(self.client + dwEntityList)
            if not ent_list:
                return 0

            list_entry = self.read_u64(ent_list + 0x8 * ((index & 0x7FFF) >> 9) + 0x10)
            if not list_entry:
                return 0

            controller = self.read_u64(list_entry + 0x78 * (index & 0x1FF))
            if not controller:
                return 0

            pawn_handle = self.read_i32(controller + m_hPlayerPawn)
            if not pawn_handle or pawn_handle == -1:
                return 0

            # resolve handle
            list_entry2 = self.read_u64(ent_list + 0x8 * ((pawn_handle & 0x7FFF) >> 9) + 0x10)
            if not list_entry2:
                return 0

            pawn = self.read_u64(list_entry2 + 0x78 * (pawn_handle & 0x1FF))
            return pawn
        except:
            return 0

# ================== SILENT AIM ==================
def find_best_target(cs, local_pawn, view_angles, local_origin):
    best_fov = FOV_LIMIT
    best_angles = None
    local_team = cs.read_i32(local_pawn + m_iTeamNum)

    for i in range(1, 64):
        pawn = cs.get_entity_pawn(i)
        if not pawn or pawn == local_pawn:
            continue

        # жив?
        if cs.read_i32(pawn + m_lifeState) != 0:
            continue
        if cs.read_i32(pawn + m_iHealth) <= 0:
            continue

        # тимчек
        if TEAM_CHECK and cs.read_i32(pawn + m_iTeamNum) == local_team:
            continue

        # позиция головы
        if HEAD_ONLY:
            head = cs.get_bone_pos(pawn, BONE_HEAD)
        else:
            head = cs.get_origin(pawn)

        if not head:
            continue

        aim_ang = calc_angle(local_origin, head)
        fov = get_fov(view_angles, aim_ang)

        if fov < best_fov:
            best_fov = fov
            best_angles = aim_ang

    return best_angles

def main():
    print("[*] CS2 Silent Aim | closest to crosshair")
    print("[*] Research / offline only\n")

    try:
        cs = CS2()
    except Exception as e:
        print(f"[!] Не удалось открыть процесс: {e}")
        print("    Запусти CS2 и повтори.")
        return

    print("[+] Attached. Работает...")

    while True:
        try:
            local = cs.get_local_pawn()
            if not local:
                time.sleep(0.01)
                continue

            origin = cs.get_origin(local)
            if not origin:
                continue

            # текущие углы
            va = cs.client + dwViewAngles
            view = [cs.read_f32(va), cs.read_f32(va + 4)]

            target = find_best_target(cs, local, view, origin)

            if target:
                # Silent: пишем углы (в реальном silent лучше только на attack)
                cs.write_angles(target[0], target[1])

            time.sleep(0.001)

        except KeyboardInterrupt:
            print("\n[*] Stopped")
            break
        except Exception as e:
            # не спамим ошибками
            time.sleep(0.02)

if __name__ == "__main__":
    main()