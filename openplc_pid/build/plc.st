TYPE
  LOGLEVEL : (CRITICAL, WARNING, INFO, DEBUG) := INFO;
END_TYPE

FUNCTION_BLOCK LOGGER
  VAR_INPUT
    TRIG : BOOL;
    MSG : STRING;
    LEVEL : LOGLEVEL := INFO;
  END_VAR
  VAR
    TRIG0 : BOOL;
  END_VAR

  IF TRIG AND NOT TRIG0 THEN
  {{
   LogMessage(GetFbVar(LEVEL),(char*)GetFbVar(MSG, .body),GetFbVar(MSG, .len));
  }}
  END_IF;
  TRIG0:=TRIG;
END_FUNCTION_BLOCK


PROGRAM program0
  VAR
    I_PbFill : BOOL;
  END_VAR
  VAR
    Q_FillLight : BOOL;
  END_VAR
  VAR
    HMI_Fill : BOOL;
  END_VAR
  VAR
    Q_LightDischarge : BOOL;
  END_VAR
  VAR
    HMI_Dis : BOOL;
    Filling : BOOL;
    Discharging : BOOL;
    AutoMode : BOOL;
    Q_FillValve : INT;
    Q_DischargeValve : INT;
    Q_Display : INT;
    LevelRaw : INT;
    I_PbDischarge : BOOL;
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
    SP : REAL := 30.0;
    PV : REAL;
    PV_lo : INT;
    PV_hi : INT;
    SP_lo : INT;
    SP_hi : INT;
  END_VAR
  VAR
    U_Manual : REAL;
    U_Auto : REAL;
  END_VAR
  VAR
    Kp : REAL := 4.0;
    Ki : REAL := 0.02;
    Kd : REAL := 0.4;
    Kp_lo : INT;
    Kp_hi : INT;
    Ki_lo : INT;
    Ki_hi : INT;
    Kd_lo : INT;
    Kd_hi : INT;
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
