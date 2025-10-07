PROGRAM program0
  VAR
    I_PbFill AT %IX100.0 : BOOL;
    I_PbDischarge AT %IX100.1 : BOOL;
    Q_FillValve AT %QW100 : INT;
    Q_DischargeValve AT %QW101 : INT;
    Q_FillLight AT %QX100.1 : BOOL;
    Q_LightDischarge AT %QX100.3 : BOOL;
    Filling AT %QX100.4 : BOOL;
    Discharging AT %QX100.5 : BOOL;
    Q_Display AT %QW102 : INT;
    LevelRaw AT %IW100 : INT;
  END_VAR
  VAR
    LevelPct : REAL;
    TimeFilling : TIME;
    TimeFillingInt : INT;
    TimeDiscarging : TIME;
    TimeDiscargingInt : INT;
    pbFill_prev : BOOL;
    pbDis_prev : BOOL;
    r_edge_fill : BOOL;
    f_edge_dis : BOOL;
    PID0 : PID;
    AutoMode : BOOL := TRUE;
    AutoMode_prev : BOOL;
  END_VAR
  VAR
    SP AT %MD100 : REAL := 30.0;
    PV AT %MD101 : REAL;
  END_VAR
  VAR
    Preset : INT;
    U_Manual : REAL;
    U_Auto : REAL;
    U : REAL;
    Kp : REAL := 1.0;
    Ki : REAL := 0.0;
    Kd : REAL := 0.0;
    tmp : REAL;
    IntTerm : REAL;
    Ts_s : REAL := 0.1;
    error : REAL;
    error_prev : REAL;
    derror : REAL;
  END_VAR

  (* ===== Edges ===== *)
  r_edge_fill := I_PbFill AND NOT pbFill_prev;
  f_edge_dis  := pbDis_prev AND NOT I_PbDischarge;

  pbFill_prev := I_PbFill;
  pbDis_prev  := I_PbDischarge;

  (* ===== Latches ===== *)
  IF r_edge_fill AND NOT Discharging THEN
      Filling := TRUE;                (* habilita modo AUTO *)

      (* reset PID ao iniciar *)
      IntTerm    := 0.0;
      error_prev := 0.0;
      U          := 0.0;
  END_IF;

  IF f_edge_dis THEN
      Discharging := TRUE;            (* força esvaziar *)
      Filling     := FALSE;

      (* reset geral ao descarregar *)
      IntTerm    := 0.0;
      error_prev := 0.0;
      U          := 0.0;
  END_IF;

  (* ======= MEDIÇÃO / PV =======  (0..1) *)
  tmp := INT_TO_REAL(LevelRaw) / 1000.0;
  IF tmp < 0.0 THEN tmp := 0.0; END_IF;
  IF tmp > 1.0 THEN tmp := 1.0; END_IF;

  LevelPct := tmp * 100.0;    (* 0..100 *)
  PV       := tmp;            (* 0..1 *)

  (* auto stop da descarga quando ~0% *)
  IF Discharging AND ((PV * 100.0) <= 1.0) THEN
      Discharging := FALSE;
  END_IF;

  (* ======= PID bidirecional (controla fill/discharge) ======= *)
  error := (SP / 100.0) - PV;    (* erro normalizado *)

  IF Filling THEN
      (* integra e deriva no domínio normalizado *)
      IntTerm := IntTerm + (Ki * error * Ts_s);
      derror  := (error - error_prev) / Ts_s;

      (* saída normalizada: -1..+1 *)
      U_Auto := (Kp * error) + IntTerm + (Kd * derror);

      (* saturação *)
      IF U_Auto >  1.0 THEN U_Auto :=  1.0; END_IF;
      IF U_Auto < -1.0 THEN U_Auto := -1.0; END_IF;

      (* anti-windup *)
      IF ((U_Auto =  1.0) AND (error > 0.0)) OR
         ((U_Auto = -1.0) AND (error < 0.0)) THEN
          IntTerm := IntTerm - (Ki * error * Ts_s);
      END_IF;

      (* mapeamento para válvulas analógicas *)
      IF U_Auto >= 0.0 THEN
          Q_FillValve      := REAL_TO_INT(1000.0 *  U_Auto);
          Q_DischargeValve := 0;
      ELSE
          Q_DischargeValve := REAL_TO_INT(1000.0 * (-U_Auto));
          Q_FillValve      := 0;
      END_IF;
  ELSE
      (* sem AUTO: saída do PID zerada *)
      Q_FillValve      := 0;
      Q_DischargeValve := 0;
  END_IF;

  error_prev := error;

  (* --- prioridade para descarga manual forçada --- *)
  IF Discharging THEN
      Q_FillValve      := 0;
      Q_DischargeValve := 1000;
  END_IF;

  (*  ------------ outros outputs ----------- *)
  Q_Display        := REAL_TO_INT(PV * 100.0);
  Q_FillLight      := Filling;
  Q_LightDischarge := Discharging;
END_PROGRAM


CONFIGURATION Config0

  RESOURCE Res0 ON PLC
    TASK task0(INTERVAL := T#20ms,PRIORITY := 0);
    PROGRAM instance0 WITH task0 : program0;
  END_RESOURCE
END_CONFIGURATION

(*DBG:char md5[] = "dcc0e5e5fd82071efab7488537b075e7";*)
(*DBG:/**)
(*DBG: * This file is part of OpenPLC Runtime*)
(*DBG: **)
(*DBG: * Copyright (C) 2023 Autonomy, GP Orcullo*)
(*DBG: * Based on the work by GP Orcullo on Beremiz for uC*)
(*DBG: **)
(*DBG: * This program is free software; you can redistribute it and/or*)
(*DBG: * modify it under the terms of the GNU General Public License*)
(*DBG: * as published by the Free Software Foundation; either version 2*)
(*DBG: * of the License, or (at your option) any later version.*)
(*DBG: **)
(*DBG: * This program is distributed in the hope that it will be useful,*)
(*DBG: * but WITHOUT ANY WARRANTY; without even the implied warranty of*)
(*DBG: * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the*)
(*DBG: * GNU General Public License for more details.*)
(*DBG: **)
(*DBG: * You should have received a copy of the GNU General Public License*)
(*DBG: * along with this program; If not, see <http://www.gnu.org/licenses/>.*)
(*DBG: **)
(*DBG: */*)
(*DBG:*)
(*DBG:#include <stdbool.h>*)
(*DBG:*)
(*DBG:#include "iec_types_all.h"*)
(*DBG:#include "POUS.h"*)
(*DBG:*)
(*DBG:#define SAME_ENDIANNESS      0*)
(*DBG:#define REVERSE_ENDIANNESS   1*)
(*DBG:*)
(*DBG:uint8_t endianness;*)
(*DBG:*)
(*DBG:*)
(*DBG:extern PROGRAM0 RES0__INSTANCE0;*)
(*DBG:*)
(*DBG:static const struct {*)
(*DBG:    void *ptr;*)
(*DBG:    __IEC_types_enum type;*)
(*DBG:} debug_vars[] = {*)
(*DBG:    {&(RES0__INSTANCE0.I_PBFILL), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.I_PBDISCHARGE), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_FILLVALVE), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_DISCHARGEVALVE), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_FILLLIGHT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_LIGHTDISCHARGE), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FILLING), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.DISCHARGING), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_DISPLAY), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LEVELRAW), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LEVELPCT), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEFILLING), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEFILLINGINT), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEDISCARGING), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEDISCARGINGINT), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PBFILL_PREV), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PBDIS_PREV), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.R_EDGE_FILL), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.F_EDGE_DIS), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.AUTO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.PV), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.SP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.X0), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.KP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.TR), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.TD), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.CYCLE), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.XOUT), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ERROR), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.RUN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.R1), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.XIN), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.X0), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.CYCLE), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.Q), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.ITERM.XOUT), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.EN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.ENO), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.RUN), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.XIN), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.CYCLE), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.XOUT), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.X1), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.X2), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PID0.DTERM.X3), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.AUTOMODE), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.AUTOMODE_PREV), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PV), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PRESET), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.U_MANUAL), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.U_AUTO), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.U), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KI), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KD), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TMP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.INTTERM), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TS_S), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ERROR), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ERROR_PREV), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.DERROR), REAL_ENUM},*)
(*DBG:};*)
(*DBG:*)
(*DBG:#define VAR_COUNT               66*)
(*DBG:*)
(*DBG:uint16_t get_var_count(void)*)
(*DBG:{*)
(*DBG:    return VAR_COUNT;*)
(*DBG:}*)
(*DBG:*)
(*DBG:size_t get_var_size(size_t idx)*)
(*DBG:{*)
(*DBG:    if (idx >= VAR_COUNT)*)
(*DBG:    {*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return sizeof(REAL);*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return sizeof(INT);*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return sizeof(TIME);*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return sizeof(BOOL);*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void *get_var_addr(size_t idx)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    switch (debug_vars[idx].type) {*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return (void *)&((__IEC_REAL_t *) ptr)->value;*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return (void *)&((__IEC_INT_t *) ptr)->value;*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return (void *)&((__IEC_TIME_t *) ptr)->value;*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return (void *)&((__IEC_BOOL_t *) ptr)->value;*)
(*DBG:    default:*)
(*DBG:        return 0;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void force_var(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    void *ptr = debug_vars[idx].ptr;*)
(*DBG:*)
(*DBG:    if (forced) {*)
(*DBG:        size_t var_size = get_var_size(idx);*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case REAL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_REAL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_REAL_t *) ptr)->value = *((REAL *) val);*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case INT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_INT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_INT_t *) ptr)->value = *((INT *) val);*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case TIME_ENUM: {*)
(*DBG:            memcpy(&((__IEC_TIME_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_TIME_t *) ptr)->value = *((TIME *) val);*)
(*DBG:            ((__IEC_TIME_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case BOOL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_BOOL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_BOOL_t *) ptr)->value = *((BOOL *) val);*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    } else {*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case REAL_ENUM:*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case INT_ENUM:*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case TIME_ENUM:*)
(*DBG:            ((__IEC_TIME_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case BOOL_ENUM:*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void swap_bytes(void *ptr, size_t size) *)
(*DBG:{*)
(*DBG:    uint8_t *bytePtr = (uint8_t *)ptr;*)
(*DBG:    size_t i;*)
(*DBG:    for (i = 0; i < size / 2; ++i) *)
(*DBG:    {*)
(*DBG:        uint8_t temp = bytePtr[i];*)
(*DBG:        bytePtr[i] = bytePtr[size - 1 - i];*)
(*DBG:        bytePtr[size - 1 - i] = temp;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void trace_reset(void)*)
(*DBG:{*)
(*DBG:    for (size_t i=0; i < VAR_COUNT; i++) *)
(*DBG:    {*)
(*DBG:        force_var(i, false, 0);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_trace(size_t idx, bool forced, void *val)*)
(*DBG:{*)
(*DBG:    if (idx >= 0 && idx < VAR_COUNT) *)
(*DBG:    {*)
(*DBG:        if (endianness == REVERSE_ENDIANNESS)*)
(*DBG:        {*)
(*DBG:            // Aaaaarghhhh... Stupid AVR is Big Endian.*)
(*DBG:            swap_bytes(val, get_var_size(idx));*)
(*DBG:        }*)
(*DBG:*)
(*DBG:        force_var(idx, forced, val);*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)
(*DBG:void set_endianness(uint8_t value)*)
(*DBG:{*)
(*DBG:    if (value == SAME_ENDIANNESS || value == REVERSE_ENDIANNESS)*)
(*DBG:    {*)
(*DBG:        endianness = value;*)
(*DBG:    }*)
(*DBG:}*)
(*DBG:*)