/*
Assignment 2- COMP214

Assignment 3-9: Retrieving Pledge Totals Create a PL/SQL block that 
retrieves and displays information for a specific project based on 
Project ID. Display the following on a single row of output: project ID, 
project name, number of pledges made, total dollars pledged, and the average 
pledge amount.
*/

DECLARE
    TYPE pledge_record IS RECORD (
        projectId dd_pledge.idproj%TYPE,
        projectName dd_project.projname%TYPE,
        pledges NUMBER,
        total_amount NUMBER,
        avg_amount NUMBER
    );
    TYPE pledge_table IS TABLE OF pledge_record;
    pledge_data pledge_table;
BEGIN
    SELECT p.idproj AS projectId, pj.projname AS projectName, 
        COUNT(p.idpledge) AS pledges, SUM(p.pledgeamt) AS total_amount, 
        AVG(p.pledgeamt) AS avg_amount
    BULK COLLECT INTO pledge_data
    FROM dd_pledge p
    JOIN dd_project pj ON p.idproj = pj.idproj
    GROUP BY p.idproj, pj.projname;

    FOR i IN 1..pledge_data.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Project ID: ' || pledge_data(i).projectId ||
            ', Project Name: ' || pledge_data(i).projectName ||
            ', No. of Pledges: ' || pledge_data(i).pledges || 
            ', Ttl Pledged Amt: ' || 
            TO_CHAR(pledge_data(i).total_amount,'$99,999.99') ||
            ', Avg Pledged Amt: ' || 
            TO_CHAR(pledge_data(i).avg_amount,'$99,999.99'));
    END LOOP;
END;


/* Assignment 3-10: Adding a Project Create a PL/SQL block to handle adding a 
new project. Create and use a sequence named DD_PROJID_SEQ to handle 
generating and populating the project ID. The first number issued by 
this sequence should be 530, and no caching should be used. Use a record 
variable to handle the data to be added. Data for the new row should be 
the following: project name = HK Animal Shelter Extension, start = 1/1/2013, 
end = 5/31/2013, and fundraising goal = $65,000. Any columns not addressed 
in the data list are currently unknown.
*/

CREATE SEQUENCE DD_PROJID_SEQ
START WITH 530
INCREMENT BY 1
NOCACHE;

DECLARE
    rec_project dd_project%ROWTYPE;
BEGIN
    rec_project.idproj := DD_PROJID_SEQ.NEXTVAL;
    rec_project.projname := 'HK Animal Shelter Extension';
    rec_project.projstartdate := TO_DATE('01-JAN-2013', 'DD-MON-YYYY');
    rec_project.projenddate := TO_DATE('31-MAY-2013', 'DD-MON-YYYY');
    rec_project.projfundgoal := 65000;
    rec_project.projcoord := NULL;
    
    INSERT INTO dd_project -- INSERT using record variable
        VALUES rec_project;
    
    DBMS_OUTPUT.PUT_LINE('New Project Added: ');
    DBMS_OUTPUT.PUT_LINE('Project ID: ' || rec_project.idproj);
    DBMS_OUTPUT.PUT_LINE('Project Name: ' || rec_project.projname);
    DBMS_OUTPUT.PUT_LINE('Start Date: ' || 
        TO_CHAR(rec_project.projstartdate, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('End Date: ' || 
        TO_CHAR(rec_project.projenddate, 'DD-MON-YYYY')); 
    DBMS_OUTPUT.PUT_LINE('Fundraising Goal: $' || rec_project.projfundgoal);
END;

-- To check
SELECT *
FROM dd_project;

/* Assignment 3-11: Retrieving and Displaying Pledge Data Create a 
PL/SQL block to retrieve and display data for all pledges made in a 
specified month. One row of output should be displayed for each pledge. 
Include the following in each row of output:

• Pledge ID, donor ID, and pledge amount • If the pledge is being paid in a 
lump sum, display “Lump Sum.” • If the pledge is being paid in monthly 
payments, display “Monthly - #” (with the # representing the number of 
months for payment). • The list should be sorted to display all lump sum 
pledges first.
*/

DECLARE
    TYPE pledge_record IS RECORD (
        idpledge dd_pledge.idpledge%TYPE,
        iddonor dd_pledge.iddonor%TYPE,
        pledgedate dd_pledge.pledgedate%TYPE,
        pledgeamt dd_pledge.pledgeamt%TYPE,
        paymonths dd_pledge.paymonths%TYPE
    );
    
    TYPE pledge_table IS TABLE OF pledge_record;
    pledge_data pledge_table;
    -- Set query values for MONTH and YEAR
    v_month NUMBER := 10;
    v_year NUMBER := 2012;
BEGIN 
    SELECT idpledge, iddonor, pledgedate, pledgeamt, paymonths
    BULK COLLECT INTO pledge_data
    FROM dd_pledge
    WHERE EXTRACT(MONTH FROM pledgedate) = v_month
        AND EXTRACT(YEAR FROM pledgedate) = v_year
    ORDER BY CASE WHEN paymonths = 0 THEN 0 ELSE 1 END, idpledge;
    
    IF pledge_data.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('No data found!');
    END IF;
    
    FOR i IN 1..pledge_data.COUNT LOOP
        DBMS_OUTPUT.PUT_LINE('Pledge ID: ' || pledge_data(i).idpledge ||
            ', Donor ID: ' || pledge_data(i).iddonor || 
            ', Pledge Amount: ' || pledge_data(i).pledgeamt ||
            CASE 
                WHEN pledge_data(i).paymonths = 0 THEN
                    ', Lump Sum'
                ELSE ', Monthly - ' || pledge_data(i).paymonths
            END);
    END LOOP;
END;

/* Assignment 3-12: Retrieving a Specific Pledge Create a PL/SQL block to 
retrieve and display information for a specific pledge. Display the 
pledge ID, donor ID, pledge amount, total paid so far, and the difference 
between the pledged amount and total paid amount. */

DECLARE
    lv_pledge_id dd_pledge.idpledge%TYPE := 103;
    lv_pledge_amount dd_pledge.pledgeamt%TYPE;
    lv_total_paid NUMBER := 0;
    lv_difference NUMBER;
    lv_donor_id dd_pledge.iddonor%TYPE;
BEGIN
    SELECT iddonor, pledgeamt
    INTO lv_donor_id, lv_pledge_amount
    FROM dd_pledge
    WHERE idpledge = lv_pledge_id;
    
    -- Calculate total paid so far
    SELECT NVL(SUM(payamt), 0)
    INTO lv_total_paid
    FROM dd_payment
    WHERE idpledge = lv_pledge_id;
    
    -- Calculate diff bet pledge amt and total paid
    lv_difference := lv_pledge_amount - lv_total_paid;
    
    DBMS_OUTPUT.PUT_LINE('Pledge ID: ' || lv_pledge_id);
    DBMS_OUTPUT.PUT_LINE('Donor ID: ' || lv_donor_id);
    DBMS_OUTPUT.PUT_LINE('Pledge Amount: ' || lv_pledge_amount);
    DBMS_OUTPUT.PUT_LINE('Total Paid So Far: ' || lv_total_paid);
    DBMS_OUTPUT.PUT_LINE('Difference: ' || lv_difference);
END;

/* Assignment 3-13: Modifying Data Create a PL/SQL block to modify the 
fundraising goal amount for a specific project. In addition, display the 
following information for the project being modified: project name, 
start date, previous fundraising goal amount, and new fundraising goal 
amount.
*/

DECLARE
    rec_project dd_project%ROWTYPE;
    lv_previous_fundraising_goal NUMBER;
    lv_new_fundraising_goal NUMBER := 75000;
BEGIN
    SELECT *
    INTO rec_project
    FROM dd_project
    WHERE idproj = 530;
    
    -- store previous fundraising goal
    lv_previous_fundraising_goal := rec_project.projfundgoal;
    
    -- update fundraising goal in record variable
    rec_project.projfundgoal := lv_new_fundraising_goal;
    
    -- update project information in database
    UPDATE dd_project
    SET ROW = rec_project
    WHERE idproj = rec_project.idproj;
    
    DBMS_OUTPUT.PUT_LINE('Project Name: ' || rec_project.projname);
    DBMS_OUTPUT.PUT_LINE('Start Date: ' || 
        TO_CHAR(rec_project.projstartdate, 'DD-MON-YYYY'));
    DBMS_OUTPUT.PUT_LINE('Previous Fundraising Goal: $' || 
        lv_previous_fundraising_goal);
    DBMS_OUTPUT.PUT_LINE('New Fundraising Goal: $' || rec_project.projfundgoal);

END;
    