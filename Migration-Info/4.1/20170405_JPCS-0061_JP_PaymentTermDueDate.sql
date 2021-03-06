﻿-- Function: adempiere.paymenttermduedate(numeric, timestamp with time zone)

-- DROP FUNCTION adempiere.paymenttermduedate(numeric, timestamp with time zone);

CREATE OR REPLACE FUNCTION adempiere.JP_PaymentTermDueDate(PaymentTerm_ID numeric, DocDate timestamp with time zone)
  RETURNS timestamp with time zone AS
$BODY$


/*************************************************************************
 * The contents of this file are subject to the Compiere License.  You may
 * obtain a copy of the License at    http://www.compiere.org/license.html
 * Software is on an  "AS IS" basis,  WITHOUT WARRANTY OF ANY KIND, either
 * express or implied. See the License for details. Code: Compiere ERP+CRM
 * Copyright (C) 1999-2001 Jorg Janke, ComPiere, Inc. All Rights Reserved.
 *
 * converted to postgreSQL by Karsten Thiemann (Schaeffer AG), 
 * kthiemann@adempiere.org
 *************************************************************************
 * Title:	Get Due timestamp with time zone
 * Description:
 *	Returns the due timestamp with time zone
 * Test:
 *	select paymenttermDueDate(106, now()) from Test; => now()+30 days
 ************************************************************************/


DECLARE
 	Days				NUMERIC := 0;
 	FixMonthOffset		Integer := 0;
 	FixMonthOffsetChar  varchar;
	DueDate				timestamp with time zone := TRUNC(DocDate);
	--
	FirstDay			timestamp with time zone;
	NoDays				NUMERIC;
	p   				RECORD;

BEGIN
	FOR p IN 
		SELECT	*
		FROM	C_PaymentTerm
		WHERE	C_PaymentTerm_ID = PaymentTerm_ID
	LOOP
		IF (p.IsDueFixed = 'Y') THEN
				FirstDay := TRUNC(DocDate, 'MM');
				NoDays := EXTRACT(day FROM TRUNC(DocDate) - FirstDay); -- Days from FirstDay of the DocDate's Month to DocDate
			IF (p.FixMonthDay = 31) THEN
				IF (NoDays >= p.FixMonthCutoff) THEN
			    	FixMonthOffset := p.FixMonthOffset + 2;
			    ELSE
			    	FixMonthOffset := p.FixMonthOffset + 1;
			    END IF;
			    DueDate := ADD_MONTHS(DueDate, FixMonthOffset);
			    DueDate := DATE_TRUNC('month', DueDate);
			    DueDate := DueDate - 1;
			    
			    IF(p.IsDueDateBizDayOnlyJP) THEN
					IF(p.IsDueDateHolidayNextBizDayJP) THEN
						DueDate := JP_NextBusinessDay(Duedate, p.JP_Calendar_ID);
					ELSE
						DueDate := JP_PreviousBusinessDay(Duedate, p.JP_Calendar_ID);
					END IF;
				END IF;

			ELSE
				DueDate := ADD_MONTHS(FirstDay, p.FixMonthOffset);
				IF (NoDays >= p.FixMonthCutoff) THEN
					DueDate := ADD_MONTHS(DueDate, 1);
				END IF;
				DueDate := DueDate + (p.FixMonthDay-1);
				
			    IF(p.IsDueDateBizDayOnlyJP) THEN
					IF(p.IsDueDateHolidayNextBizDayJP) THEN
						DueDate := JP_NextBusinessDay(Duedate, p.JP_Calendar_ID);
					ELSE
						DueDate := JP_PreviousBusinessDay(Duedate, p.JP_Calendar_ID);
					END IF;
				END IF;
								
			END IF;
		ELSE
			DueDate := TRUNC(DocDate) + p.NetDays;
			IF(p.IsDueDateBizDayOnlyJP) THEN
				IF(p.IsDueDateHolidayNextBizDayJP) THEN
						DueDate := JP_NextBusinessDay(Duedate, p.JP_Calendar_ID);
				ELSE
						DueDate := JP_PreviousBusinessDay(Duedate, p.JP_Calendar_ID);
				END IF;
			END IF;
			
		END IF;
	END LOOP;
	RETURN DueDate;
END;
$BODY$
  LANGUAGE plpgsql STABLE
  COST 100;
ALTER FUNCTION adempiere.JP_PaymentTermDueDate(numeric, timestamp with time zone)
  OWNER TO adempiere;