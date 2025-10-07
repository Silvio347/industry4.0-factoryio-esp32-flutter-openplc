PROGRAM program0
  VAR
    I_PbFill AT %IX100.0 : BOOL;
  END_VAR
  VAR
    Q_FillLight : BOOL;
  END_VAR
  VAR
    HMI_Fill AT %QX100.2 : BOOL;
  END_VAR
  VAR
    Q_LightDischarge : BOOL;
  END_VAR
  VAR
    HMI_Dis AT %QX100.3 : BOOL;
    Filling AT %QX100.4 : BOOL;
    Discharging AT %QX100.5 : BOOL;
    AutoMode AT %QX100.6 : BOOL;
    Q_FillValve AT %QW100 : INT;
    Q_DischargeValve AT %QW101 : INT;
    Q_Display AT %QW102 : INT;
    LevelRaw AT %IW100 : INT;
    I_PbDischarge AT %IX100.1 : BOOL;
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
    r_edge_auto : BOOL;
    f_edge_dis : BOOL;
    PID0 : PID;
    AutoMode_prev : BOOL;
  END_VAR
  VAR
    SP AT %MD100 : REAL := 30.0;
    PV AT %MD102 : REAL;
    PV_lo AT %QW206 : INT;
    PV_hi AT %QW207 : INT;
    SP_lo AT %QW208 : INT;
    SP_hi AT %QW209 : INT;
  END_VAR
  VAR
    U_Manual : REAL;
    U_Auto : REAL;
  END_VAR
  VAR
    Kp AT %MD200 : REAL := 4.0;
    Ki AT %MD202 : REAL := 0.02;
    Kd AT %MD204 : REAL := 0.4;
    Kp_lo AT %QW200 : INT;
    Kp_hi AT %QW201 : INT;
    Ki_lo AT %QW202 : INT;
    Ki_hi AT %QW203 : INT;
    Kd_lo AT %QW204 : INT;
    Kd_hi AT %QW205 : INT;
  END_VAR
  VAR
    tmp : REAL;
    IntTerm : REAL;
    Ts_s : REAL := 0.1;
    error : REAL;
    error_prev : REAL;
    derror : REAL;
    _raw_di : DINT;
    _loW : WORD;
    _hiW : WORD;
    _loDW : DWORD;
    _hiDW : DWORD;
    _raw_dw : DWORD;
  END_VAR

  _loDW   := WORD_TO_DWORD(INT_TO_WORD(Kp_lo));
  _hiDW   := SHL(WORD_TO_DWORD(INT_TO_WORD(Kp_hi)), 16);
  _raw_dw := _loDW OR _hiDW;
  _raw_di := DWORD_TO_DINT(_raw_dw);
  Kp := DINT_TO_REAL(_raw_di) / 10000.0;

  (* Repete para Ki/Kd *)
  _loDW   := WORD_TO_DWORD(INT_TO_WORD(Ki_lo));
  _hiDW   := SHL(WORD_TO_DWORD(INT_TO_WORD(Ki_hi)), 16);
  _raw_dw := _loDW OR _hiDW;
  _raw_di := DWORD_TO_DINT(_raw_dw);
  Ki := DINT_TO_REAL(_raw_di) / 10000.0;

  _loDW   := WORD_TO_DWORD(INT_TO_WORD(Kd_lo));
  _hiDW   := SHL(WORD_TO_DWORD(INT_TO_WORD(Kd_hi)), 16);
  _raw_dw := _loDW OR _hiDW;
  _raw_di := DWORD_TO_DINT(_raw_dw);
  Kd := DINT_TO_REAL(_raw_di) / 10000.0;


  _loDW   := WORD_TO_DWORD(INT_TO_WORD(SP_lo));
  _hiDW   := SHL(WORD_TO_DWORD(INT_TO_WORD(SP_hi)), 16);
  _raw_dw := _loDW OR _hiDW;
  _raw_di := DWORD_TO_DINT(_raw_dw);
  SP := DINT_TO_REAL(_raw_di) / 10000.0;


  (* PV já está em 0..1 (ex.: calculado de LevelRaw). Agora exporta em LO/HI ×10000 *)
  _raw_di := REAL_TO_DINT(PV * 10000.0);
  _raw_dw := DINT_TO_DWORD(_raw_di);

  PV_lo := WORD_TO_INT(DWORD_TO_WORD(_raw_dw));                 (* LOW  *)
  PV_hi := WORD_TO_INT(DWORD_TO_WORD(SHR(_raw_dw, 16)));        (* HIGH *)


      (* ===== Factory IO Inputs ===== *)



      r_edge_fill := I_PbFill AND NOT pbFill_prev;

      f_edge_dis  := pbDis_prev AND NOT I_PbDischarge;

      pbFill_prev := I_PbFill;

      pbDis_prev  := I_PbDischarge;



      IF r_edge_fill AND NOT Discharging AND NOT AutoMode THEN

          Filling := TRUE;



          (* reset PID ao iniciar *)

          IntTerm    := 0.0;

          error_prev := 0.0;

      END_IF;



      IF f_edge_dis AND NOT AutoMode THEN

          Discharging := TRUE; 

          Filling     := FALSE;



          (* reset geral ao descarregar *)

          IntTerm    := 0.0;

          error_prev := 0.0;

      END_IF;







      (* ======= PV =======  (0..1) *)



      tmp := INT_TO_REAL(LevelRaw) / 1000.0;



      IF tmp < 0.0 THEN tmp := 0.0; END_IF;

      IF tmp > 1.0 THEN tmp := 1.0; END_IF;



      LevelPct := tmp * 100.0;    (* 0..100 *)

      PV       := tmp;            (* 0..1 *)



      (* auto stop da descarga quando ~0% *)

      IF Discharging AND ((PV * 100.0) <= 1.0) THEN

          Discharging := FALSE;

      END_IF;







      (* ======= AUTO/MAN MODE =======  *)

      

      r_edge_auto := AutoMode AND NOT AutoMode_prev; 

      AutoMode_prev := AutoMode;

      

      IF AutoMode THEN

          (* reset só quando entra em AUTO *)

          IF r_edge_auto THEN

              Filling     := FALSE;

              Discharging := FALSE;

              IntTerm     := 0.0;

              error_prev  := 0.0;

              U_Auto      := 0.0;

          END_IF;



          (* ---------- PID SEMPRE ATIVO NO AUTO ---------- *)

          error   := (SP / 100.0) - PV;

          IntTerm := IntTerm + (Ki * error * Ts_s);

          derror  := (error - error_prev) / Ts_s;



          U_Auto := (Kp * error) + IntTerm + (Kd * derror);



          (* saturação *)

          IF U_Auto >  1.0 THEN U_Auto :=  1.0; END_IF;

          IF U_Auto < -1.0 THEN U_Auto := -1.0; END_IF;



          (* anti-windup *)

          IF ((U_Auto =  1.0) AND (error > 0.0)) OR

             ((U_Auto = -1.0) AND (error < 0.0)) THEN

              IntTerm := IntTerm - (Ki * error * Ts_s);

          END_IF;



          (* mapeamento 0..1000 e estados *)

          IF U_Auto > 0.0 THEN

              Q_FillValve      := REAL_TO_INT(1000.0 *  U_Auto);

              Q_DischargeValve := 0;
              

              Filling          := TRUE;

              Discharging      := FALSE;

          ELSIF U_Auto < 0.0 THEN

              Q_DischargeValve := REAL_TO_INT(1000.0 * (-U_Auto));

              Q_FillValve      := 0;

              Filling          := FALSE;

              Discharging      := TRUE;

          ELSE

              Q_FillValve      := 0;

              Q_DischargeValve := 0;

              Filling          := FALSE;

              Discharging      := FALSE;

          END_IF;



      (* ---------- MANUAL ---------- *)

      ELSE

          IF HMI_Dis THEN

              Q_DischargeValve := 1000;

              Q_FillValve      := 0;

              Discharging      := TRUE;

              Filling          := FALSE;

          ELSIF HMI_Fill THEN

              Q_FillValve      := 1000;   (* abre 100% *)

              Q_DischargeValve := 0;

              Filling          := TRUE;

              Discharging      := FALSE;

          ELSE

              HMI_Dis          := 0;

              Q_FillValve      := 0;

              Q_DischargeValve := 0;

              Filling          := FALSE;

              Discharging      := FALSE;

          END_IF;

      END_IF;







      error            := (SP / 100.0) - PV;

      error_prev       := error;

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

(*DBG:char md5[] = "772f98d6063cb084e24f4a5bd48c3b24";*)
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
(*DBG:    {&(RES0__INSTANCE0.Q_FILLLIGHT), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.HMI_FILL), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_LIGHTDISCHARGE), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.HMI_DIS), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.FILLING), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.DISCHARGING), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.AUTOMODE), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_FILLVALVE), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_DISCHARGEVALVE), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.Q_DISPLAY), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LEVELRAW), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.I_PBDISCHARGE), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.LEVELPCT), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEFILLING), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEFILLINGINT), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEDISCARGING), TIME_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TIMEDISCARGINGINT), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PBFILL_PREV), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PBDIS_PREV), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.R_EDGE_FILL), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.R_EDGE_AUTO), BOOL_ENUM},*)
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
(*DBG:    {&(RES0__INSTANCE0.AUTOMODE_PREV), BOOL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PV), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PV_LO), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.PV_HI), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SP_LO), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.SP_HI), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.U_MANUAL), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.U_AUTO), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KI), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KD), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KP_LO), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KP_HI), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KI_LO), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KI_HI), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KD_LO), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.KD_HI), INT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TMP), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.INTTERM), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.TS_S), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ERROR), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.ERROR_PREV), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0.DERROR), REAL_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._RAW_DI), DINT_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._LOW), WORD_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._HIW), WORD_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._LODW), DWORD_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._HIDW), DWORD_ENUM},*)
(*DBG:    {&(RES0__INSTANCE0._RAW_DW), DWORD_ENUM},*)
(*DBG:};*)
(*DBG:*)
(*DBG:#define VAR_COUNT               83*)
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
(*DBG:    case DINT_ENUM:*)
(*DBG:        return sizeof(DINT);*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return sizeof(BOOL);*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return sizeof(INT);*)
(*DBG:    case WORD_ENUM:*)
(*DBG:        return sizeof(WORD);*)
(*DBG:    case DWORD_ENUM:*)
(*DBG:        return sizeof(DWORD);*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return sizeof(TIME);*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return sizeof(REAL);*)
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
(*DBG:    case DINT_ENUM:*)
(*DBG:        return (void *)&((__IEC_DINT_t *) ptr)->value;*)
(*DBG:    case BOOL_ENUM:*)
(*DBG:        return (void *)&((__IEC_BOOL_t *) ptr)->value;*)
(*DBG:    case INT_ENUM:*)
(*DBG:        return (void *)&((__IEC_INT_t *) ptr)->value;*)
(*DBG:    case WORD_ENUM:*)
(*DBG:        return (void *)&((__IEC_WORD_t *) ptr)->value;*)
(*DBG:    case DWORD_ENUM:*)
(*DBG:        return (void *)&((__IEC_DWORD_t *) ptr)->value;*)
(*DBG:    case TIME_ENUM:*)
(*DBG:        return (void *)&((__IEC_TIME_t *) ptr)->value;*)
(*DBG:    case REAL_ENUM:*)
(*DBG:        return (void *)&((__IEC_REAL_t *) ptr)->value;*)
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
(*DBG:        case DINT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_DINT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_DINT_t *) ptr)->value = *((DINT *) val);*)
(*DBG:            ((__IEC_DINT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case BOOL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_BOOL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_BOOL_t *) ptr)->value = *((BOOL *) val);*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case INT_ENUM: {*)
(*DBG:            memcpy(&((__IEC_INT_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_INT_t *) ptr)->value = *((INT *) val);*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case WORD_ENUM: {*)
(*DBG:            memcpy(&((__IEC_WORD_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_WORD_t *) ptr)->value = *((WORD *) val);*)
(*DBG:            ((__IEC_WORD_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case DWORD_ENUM: {*)
(*DBG:            memcpy(&((__IEC_DWORD_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_DWORD_t *) ptr)->value = *((DWORD *) val);*)
(*DBG:            ((__IEC_DWORD_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case TIME_ENUM: {*)
(*DBG:            memcpy(&((__IEC_TIME_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_TIME_t *) ptr)->value = *((TIME *) val);*)
(*DBG:            ((__IEC_TIME_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        case REAL_ENUM: {*)
(*DBG:            memcpy(&((__IEC_REAL_t *) ptr)->value, val, var_size);*)
(*DBG:            //((__IEC_REAL_t *) ptr)->value = *((REAL *) val);*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags |= __IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:        default:*)
(*DBG:            break;*)
(*DBG:        }*)
(*DBG:    } else {*)
(*DBG:        switch (debug_vars[idx].type) {*)
(*DBG:        case DINT_ENUM:*)
(*DBG:            ((__IEC_DINT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case BOOL_ENUM:*)
(*DBG:            ((__IEC_BOOL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case INT_ENUM:*)
(*DBG:            ((__IEC_INT_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case WORD_ENUM:*)
(*DBG:            ((__IEC_WORD_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case DWORD_ENUM:*)
(*DBG:            ((__IEC_DWORD_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case TIME_ENUM:*)
(*DBG:            ((__IEC_TIME_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
(*DBG:            break;*)
(*DBG:        case REAL_ENUM:*)
(*DBG:            ((__IEC_REAL_t *) ptr)->flags &= ~__IEC_FORCE_FLAG;*)
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