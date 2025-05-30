/*
Assignment 3 - Cursors, Procedures , Functions, Triggers
*/

/* Question 1 */

-- Display contents of BB_BASKETSTATUS before running the procedure
SELECT * FROM BB_BASKETSTATUS WHERE IDBASKET = 3;

CREATE OR REPLACE PROCEDURE STATUS_SHIP_SP (
    p_basket_id IN BB_BASKETSTATUS.IDBASKET%TYPE,
    p_date_shipped IN DATE,
    p_shipper IN BB_BASKETSTATUS.SHIPPER%TYPE,
    p_tracking_num IN BB_BASKETSTATUS.SHIPPINGNUM%TYPE
) IS
    v_idstage BB_BASKETSTATUS.IDSTAGE%TYPE := 3;
    v_status_id BB_BASKETSTATUS.IDSTATUS%TYPE;
BEGIN
    SELECT BB_STATUS_SEQ.NEXTVAL INTO v_status_id FROM DUAL;
    
    INSERT INTO BB_BASKETSTATUS (IDSTATUS, IDBASKET, IDSTAGE, 
        DTSTAGE, SHIPPER, SHIPPINGNUM)
    VALUES (v_status_id, p_basket_id, v_idstage, p_date_shipped,
        p_shipper, p_tracking_num);

    DBMS_OUTPUT.PUT_LINE('Order status updated for basket ID: ' || p_basket_id);
END STATUS_SHIP_SP;

-- Test
BEGIN
    STATUS_SHIP_SP(3, TO_DATE('20-FEB-12', 'DD-MON-YY'), 'UPS', 'ZW2384YXK4957');
END;

-- Display contents of BB_BASKETSTATUS after running the procedure
SELECT * FROM BB_BASKETSTATUS WHERE IDBASKET = 3;


/* Question 2 */

-- Display the most recent status for basket IDs 4 and 6
SELECT * FROM BB_BASKETSTATUS WHERE IDBASKET IN (4, 6) ORDER BY DTSTAGE DESC;

CREATE OR REPLACE PROCEDURE STATUS_SP (
    p_basket_id IN BB_BASKETSTATUS.IDBASKET%TYPE,
    p_status_description OUT VARCHAR2,
    p_status_date OUT DATE
) IS
    v_idstage BB_BASKETSTATUS.IDSTAGE%TYPE;
BEGIN
    SELECT IDSTAGE, DTSTAGE
    INTO v_idstage, p_status_date
    FROM BB_BASKETSTATUS
    WHERE IDBASKET = p_basket_id
    ORDER BY DTSTAGE DESC
    FETCH FIRST 1 ROW ONLY;
    
    CASE v_idstage
        WHEN 1 THEN p_status_description := 'Submitted and received';
        WHEN 2 THEN p_status_description := 'Confirmed, processed, sent to shipping';
        WHEN 3 THEN p_status_description := 'Shipped';
        WHEN 4 THEN p_status_description := 'Cancelled';
        WHEN 5 THEN p_status_description := 'Back-ordered';
        ELSE p_status_description := 'Unknown status';
    END CASE;

    DBMS_OUTPUT.PUT_LINE('Most recent status for basket ID ' || 
        p_basket_id || ': ' || p_status_description ||
        ', Date: ' || p_status_date);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        p_status_description := 'No status available';
        p_status_date := NULL;
        DBMS_OUTPUT.PUT_LINE('No status available for basket ID ' || p_basket_id);
END STATUS_SP;

-- Test
DECLARE
    v_status_description VARCHAR2(50);
    v_status_date DATE;
BEGIN
    STATUS_SP(4, v_status_description, v_status_date);
    STATUS_SP(6, v_status_description, v_status_date);
END;


/* Question 3 */

-- Display contents of BB_PROMOLIST before running the procedure
SELECT * FROM BB_PROMOLIST;

CREATE OR REPLACE PROCEDURE PROMO_SHIP_SP (
    p_cutoff_date IN DATE,
    p_month IN VARCHAR2,
    p_year IN NUMBER
) IS
    CURSOR inactive_customers IS
        SELECT DISTINCT IDSHOPPER
        FROM BB_BASKET
        WHERE DTCREATED < p_cutoff_date;
BEGIN
    FOR customer_rec IN inactive_customers LOOP
        INSERT INTO BB_PROMOLIST (IDSHOPPER, PROMO_FLAG, MONTH, YEAR, USED)
        VALUES (customer_rec.IDSHOPPER, 1, p_month, p_year, 'N');
        
        DBMS_OUTPUT.PUT_LINE('Promotion added for customer ID: ' ||
            customer_rec.IDSHOPPER);
    END LOOP;
END PROMO_SHIP_SP;

-- Test
BEGIN
    PROMO_SHIP_SP(TO_DATE('15-FEB-12', 'DD-MON-YY'), 'APR', 2012);
END;

-- Display contents of BB_PROMOLIST after running the procedure
SELECT * FROM BB_PROMOLIST;







