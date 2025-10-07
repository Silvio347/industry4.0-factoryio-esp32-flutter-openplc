void LOGGER_init__(LOGGER *data__, BOOL retain) {
  __INIT_VAR(data__->EN,__BOOL_LITERAL(TRUE),retain)
  __INIT_VAR(data__->ENO,__BOOL_LITERAL(TRUE),retain)
  __INIT_VAR(data__->TRIG,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->MSG,__STRING_LITERAL(0,""),retain)
  __INIT_VAR(data__->LEVEL,LOGLEVEL__INFO,retain)
  __INIT_VAR(data__->TRIG0,__BOOL_LITERAL(FALSE),retain)
}

// Code part
void LOGGER_body__(LOGGER *data__) {
  // Control execution
  if (!__GET_VAR(data__->EN)) {
    __SET_VAR(data__->,ENO,,__BOOL_LITERAL(FALSE));
    return;
  }
  else {
    __SET_VAR(data__->,ENO,,__BOOL_LITERAL(TRUE));
  }
  // Initialise TEMP variables

  if ((__GET_VAR(data__->TRIG,) && !(__GET_VAR(data__->TRIG0,)))) {
    #define GetFbVar(var,...) __GET_VAR(data__->var,__VA_ARGS__)
    #define SetFbVar(var,val,...) __SET_VAR(data__->,var,__VA_ARGS__,val)

   LogMessage(GetFbVar(LEVEL),(char*)GetFbVar(MSG, .body),GetFbVar(MSG, .len));
  
    #undef GetFbVar
    #undef SetFbVar
;
  };
  __SET_VAR(data__->,TRIG0,,__GET_VAR(data__->TRIG,));

  goto __end;

__end:
  return;
} // LOGGER_body__() 





void PROGRAM0_init__(PROGRAM0 *data__, BOOL retain) {
  __INIT_VAR(data__->I_PBFILL,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->Q_FILLLIGHT,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->HMI_FILL,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->Q_LIGHTDISCHARGE,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->HMI_DIS,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->FILLING,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->DISCHARGING,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->AUTOMODE,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->Q_FILLVALVE,0,retain)
  __INIT_VAR(data__->Q_DISCHARGEVALVE,0,retain)
  __INIT_VAR(data__->Q_DISPLAY,0,retain)
  __INIT_VAR(data__->LEVELRAW,0,retain)
  __INIT_VAR(data__->I_PBDISCHARGE,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->LEVELPCT,0,retain)
  __INIT_VAR(data__->TIMEFILLING,__time_to_timespec(1, 0, 0, 0, 0, 0),retain)
  __INIT_VAR(data__->TIMEFILLINGINT,0,retain)
  __INIT_VAR(data__->TIMEDISCARGING,__time_to_timespec(1, 0, 0, 0, 0, 0),retain)
  __INIT_VAR(data__->TIMEDISCARGINGINT,0,retain)
  __INIT_VAR(data__->PBFILL_PREV,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->PBDIS_PREV,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->R_EDGE_FILL,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->R_EDGE_AUTO,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->F_EDGE_DIS,__BOOL_LITERAL(FALSE),retain)
  PID_init__(&data__->PID0,retain);
  __INIT_VAR(data__->AUTOMODE_PREV,__BOOL_LITERAL(FALSE),retain)
  __INIT_VAR(data__->SP,30.0,retain)
  __INIT_VAR(data__->PV,0,retain)
  __INIT_VAR(data__->PV_LO,0,retain)
  __INIT_VAR(data__->PV_HI,0,retain)
  __INIT_VAR(data__->SP_LO,0,retain)
  __INIT_VAR(data__->SP_HI,0,retain)
  __INIT_VAR(data__->U_MANUAL,0,retain)
  __INIT_VAR(data__->U_AUTO,0,retain)
  __INIT_VAR(data__->KP,4.0,retain)
  __INIT_VAR(data__->KI,0.02,retain)
  __INIT_VAR(data__->KD,0.4,retain)
  __INIT_VAR(data__->KP_LO,0,retain)
  __INIT_VAR(data__->KP_HI,0,retain)
  __INIT_VAR(data__->KI_LO,0,retain)
  __INIT_VAR(data__->KI_HI,0,retain)
  __INIT_VAR(data__->KD_LO,0,retain)
  __INIT_VAR(data__->KD_HI,0,retain)
  __INIT_VAR(data__->TMP,0,retain)
  __INIT_VAR(data__->INTTERM,0,retain)
  __INIT_VAR(data__->TS_S,0.1,retain)
  __INIT_VAR(data__->ERROR,0,retain)
  __INIT_VAR(data__->ERROR_PREV,0,retain)
  __INIT_VAR(data__->DERROR,0,retain)
  __INIT_VAR(data__->_RAW_DI,0,retain)
  __INIT_VAR(data__->_LOW,0,retain)
  __INIT_VAR(data__->_HIW,0,retain)
  __INIT_VAR(data__->_LODW,0,retain)
  __INIT_VAR(data__->_HIDW,0,retain)
  __INIT_VAR(data__->_RAW_DW,0,retain)
}

// Code part
void PROGRAM0_body__(PROGRAM0 *data__) {
  // Initialise TEMP variables

  __SET_VAR(data__->,_LODW,,WORD_TO_DWORD(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (WORD)INT_TO_WORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (INT)__GET_VAR(data__->KP_LO,))));
  __SET_VAR(data__->,_HIDW,,SHL__DWORD__DWORD__SINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)WORD_TO_DWORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (WORD)INT_TO_WORD(
        (BOOL)__BOOL_LITERAL(TRUE),
        NULL,
        (INT)__GET_VAR(data__->KP_HI,))),
    (SINT)16));
  __SET_VAR(data__->,_RAW_DW,,(__GET_VAR(data__->_LODW,) | __GET_VAR(data__->_HIDW,)));
  __SET_VAR(data__->,_RAW_DI,,DWORD_TO_DINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)__GET_VAR(data__->_RAW_DW,)));
  __SET_VAR(data__->,KP,,(DINT_TO_REAL(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DINT)__GET_VAR(data__->_RAW_DI,)) / 10000.0));
  __SET_VAR(data__->,_LODW,,WORD_TO_DWORD(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (WORD)INT_TO_WORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (INT)__GET_VAR(data__->KI_LO,))));
  __SET_VAR(data__->,_HIDW,,SHL__DWORD__DWORD__SINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)WORD_TO_DWORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (WORD)INT_TO_WORD(
        (BOOL)__BOOL_LITERAL(TRUE),
        NULL,
        (INT)__GET_VAR(data__->KI_HI,))),
    (SINT)16));
  __SET_VAR(data__->,_RAW_DW,,(__GET_VAR(data__->_LODW,) | __GET_VAR(data__->_HIDW,)));
  __SET_VAR(data__->,_RAW_DI,,DWORD_TO_DINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)__GET_VAR(data__->_RAW_DW,)));
  __SET_VAR(data__->,KI,,(DINT_TO_REAL(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DINT)__GET_VAR(data__->_RAW_DI,)) / 10000.0));
  __SET_VAR(data__->,_LODW,,WORD_TO_DWORD(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (WORD)INT_TO_WORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (INT)__GET_VAR(data__->KD_LO,))));
  __SET_VAR(data__->,_HIDW,,SHL__DWORD__DWORD__SINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)WORD_TO_DWORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (WORD)INT_TO_WORD(
        (BOOL)__BOOL_LITERAL(TRUE),
        NULL,
        (INT)__GET_VAR(data__->KD_HI,))),
    (SINT)16));
  __SET_VAR(data__->,_RAW_DW,,(__GET_VAR(data__->_LODW,) | __GET_VAR(data__->_HIDW,)));
  __SET_VAR(data__->,_RAW_DI,,DWORD_TO_DINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)__GET_VAR(data__->_RAW_DW,)));
  __SET_VAR(data__->,KD,,(DINT_TO_REAL(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DINT)__GET_VAR(data__->_RAW_DI,)) / 10000.0));
  __SET_VAR(data__->,_LODW,,WORD_TO_DWORD(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (WORD)INT_TO_WORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (INT)__GET_VAR(data__->SP_LO,))));
  __SET_VAR(data__->,_HIDW,,SHL__DWORD__DWORD__SINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)WORD_TO_DWORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (WORD)INT_TO_WORD(
        (BOOL)__BOOL_LITERAL(TRUE),
        NULL,
        (INT)__GET_VAR(data__->SP_HI,))),
    (SINT)16));
  __SET_VAR(data__->,_RAW_DW,,(__GET_VAR(data__->_LODW,) | __GET_VAR(data__->_HIDW,)));
  __SET_VAR(data__->,_RAW_DI,,DWORD_TO_DINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DWORD)__GET_VAR(data__->_RAW_DW,)));
  __SET_VAR(data__->,SP,,(DINT_TO_REAL(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DINT)__GET_VAR(data__->_RAW_DI,)) / 10000.0));
  __SET_VAR(data__->,_RAW_DI,,REAL_TO_DINT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (REAL)(__GET_VAR(data__->PV,) * 10000.0)));
  __SET_VAR(data__->,_RAW_DW,,DINT_TO_DWORD(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (DINT)__GET_VAR(data__->_RAW_DI,)));
  __SET_VAR(data__->,PV_LO,,WORD_TO_INT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (WORD)DWORD_TO_WORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (DWORD)__GET_VAR(data__->_RAW_DW,))));
  __SET_VAR(data__->,PV_HI,,WORD_TO_INT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (WORD)DWORD_TO_WORD(
      (BOOL)__BOOL_LITERAL(TRUE),
      NULL,
      (DWORD)SHR__DWORD__DWORD__SINT(
        (BOOL)__BOOL_LITERAL(TRUE),
        NULL,
        (DWORD)__GET_VAR(data__->_RAW_DW,),
        (SINT)16))));
  __SET_VAR(data__->,R_EDGE_FILL,,(__GET_VAR(data__->I_PBFILL,) && !(__GET_VAR(data__->PBFILL_PREV,))));
  __SET_VAR(data__->,F_EDGE_DIS,,(__GET_VAR(data__->PBDIS_PREV,) && !(__GET_VAR(data__->I_PBDISCHARGE,))));
  __SET_VAR(data__->,PBFILL_PREV,,__GET_VAR(data__->I_PBFILL,));
  __SET_VAR(data__->,PBDIS_PREV,,__GET_VAR(data__->I_PBDISCHARGE,));
  if (((__GET_VAR(data__->R_EDGE_FILL,) && !(__GET_VAR(data__->DISCHARGING,))) && !(__GET_VAR(data__->AUTOMODE,)))) {
    __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(TRUE));
    __SET_VAR(data__->,INTTERM,,0.0);
    __SET_VAR(data__->,ERROR_PREV,,0.0);
  };
  if ((__GET_VAR(data__->F_EDGE_DIS,) && !(__GET_VAR(data__->AUTOMODE,)))) {
    __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(TRUE));
    __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(FALSE));
    __SET_VAR(data__->,INTTERM,,0.0);
    __SET_VAR(data__->,ERROR_PREV,,0.0);
  };
  __SET_VAR(data__->,TMP,,(INT_TO_REAL(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (INT)__GET_VAR(data__->LEVELRAW,)) / 1000.0));
  if ((__GET_VAR(data__->TMP,) < 0.0)) {
    __SET_VAR(data__->,TMP,,0.0);
  };
  if ((__GET_VAR(data__->TMP,) > 1.0)) {
    __SET_VAR(data__->,TMP,,1.0);
  };
  __SET_VAR(data__->,LEVELPCT,,(__GET_VAR(data__->TMP,) * 100.0));
  __SET_VAR(data__->,PV,,__GET_VAR(data__->TMP,));
  if ((__GET_VAR(data__->DISCHARGING,) && ((__GET_VAR(data__->PV,) * 100.0) <= 1.0))) {
    __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(FALSE));
  };
  __SET_VAR(data__->,R_EDGE_AUTO,,(__GET_VAR(data__->AUTOMODE,) && !(__GET_VAR(data__->AUTOMODE_PREV,))));
  __SET_VAR(data__->,AUTOMODE_PREV,,__GET_VAR(data__->AUTOMODE,));
  if (__GET_VAR(data__->AUTOMODE,)) {
    if (__GET_VAR(data__->R_EDGE_AUTO,)) {
      __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(FALSE));
      __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(FALSE));
      __SET_VAR(data__->,INTTERM,,0.0);
      __SET_VAR(data__->,ERROR_PREV,,0.0);
      __SET_VAR(data__->,U_AUTO,,0.0);
    };
    __SET_VAR(data__->,ERROR,,((__GET_VAR(data__->SP,) / 100.0) - __GET_VAR(data__->PV,)));
    __SET_VAR(data__->,INTTERM,,(__GET_VAR(data__->INTTERM,) + ((__GET_VAR(data__->KI,) * __GET_VAR(data__->ERROR,)) * __GET_VAR(data__->TS_S,))));
    __SET_VAR(data__->,DERROR,,((__GET_VAR(data__->ERROR,) - __GET_VAR(data__->ERROR_PREV,)) / __GET_VAR(data__->TS_S,)));
    __SET_VAR(data__->,U_AUTO,,(((__GET_VAR(data__->KP,) * __GET_VAR(data__->ERROR,)) + __GET_VAR(data__->INTTERM,)) + (__GET_VAR(data__->KD,) * __GET_VAR(data__->DERROR,))));
    if ((__GET_VAR(data__->U_AUTO,) > 1.0)) {
      __SET_VAR(data__->,U_AUTO,,1.0);
    };
    if ((__GET_VAR(data__->U_AUTO,) < -1.0)) {
      __SET_VAR(data__->,U_AUTO,,-1.0);
    };
    if ((((__GET_VAR(data__->U_AUTO,) == 1.0) && (__GET_VAR(data__->ERROR,) > 0.0)) || ((__GET_VAR(data__->U_AUTO,) == -1.0) && (__GET_VAR(data__->ERROR,) < 0.0)))) {
      __SET_VAR(data__->,INTTERM,,(__GET_VAR(data__->INTTERM,) - ((__GET_VAR(data__->KI,) * __GET_VAR(data__->ERROR,)) * __GET_VAR(data__->TS_S,))));
    };
    if ((__GET_VAR(data__->U_AUTO,) > 0.0)) {
      __SET_VAR(data__->,Q_FILLVALVE,,REAL_TO_INT(
        (BOOL)__BOOL_LITERAL(TRUE),
        NULL,
        (REAL)(1000.0 * __GET_VAR(data__->U_AUTO,))));
      __SET_VAR(data__->,Q_DISCHARGEVALVE,,0);
      __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(TRUE));
      __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(FALSE));
    } else if ((__GET_VAR(data__->U_AUTO,) < 0.0)) {
      __SET_VAR(data__->,Q_DISCHARGEVALVE,,REAL_TO_INT(
        (BOOL)__BOOL_LITERAL(TRUE),
        NULL,
        (REAL)(1000.0 *  -(__GET_VAR(data__->U_AUTO,)))));
      __SET_VAR(data__->,Q_FILLVALVE,,0);
      __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(FALSE));
      __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(TRUE));
    } else {
      __SET_VAR(data__->,Q_FILLVALVE,,0);
      __SET_VAR(data__->,Q_DISCHARGEVALVE,,0);
      __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(FALSE));
      __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(FALSE));
    };
  } else {
    if (__GET_VAR(data__->HMI_DIS,)) {
      __SET_VAR(data__->,Q_DISCHARGEVALVE,,1000);
      __SET_VAR(data__->,Q_FILLVALVE,,0);
      __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(TRUE));
      __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(FALSE));
    } else if (__GET_VAR(data__->HMI_FILL,)) {
      __SET_VAR(data__->,Q_FILLVALVE,,1000);
      __SET_VAR(data__->,Q_DISCHARGEVALVE,,0);
      __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(TRUE));
      __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(FALSE));
    } else {
      __SET_VAR(data__->,HMI_DIS,,0);
      __SET_VAR(data__->,Q_FILLVALVE,,0);
      __SET_VAR(data__->,Q_DISCHARGEVALVE,,0);
      __SET_VAR(data__->,FILLING,,__BOOL_LITERAL(FALSE));
      __SET_VAR(data__->,DISCHARGING,,__BOOL_LITERAL(FALSE));
    };
  };
  __SET_VAR(data__->,ERROR,,((__GET_VAR(data__->SP,) / 100.0) - __GET_VAR(data__->PV,)));
  __SET_VAR(data__->,ERROR_PREV,,__GET_VAR(data__->ERROR,));
  __SET_VAR(data__->,Q_DISPLAY,,REAL_TO_INT(
    (BOOL)__BOOL_LITERAL(TRUE),
    NULL,
    (REAL)(__GET_VAR(data__->PV,) * 100.0)));
  __SET_VAR(data__->,Q_FILLLIGHT,,__GET_VAR(data__->FILLING,));
  __SET_VAR(data__->,Q_LIGHTDISCHARGE,,__GET_VAR(data__->DISCHARGING,));

  goto __end;

__end:
  return;
} // PROGRAM0_body__() 





