USE [IQCare_CPAD] 

go 

/****** Object:  StoredProcedure [dbo].[SP_Bluecard_ToGreenCard]    Script Date: 12/17/2018 4:06:31 PM ******/ 
SET ansi_nulls ON 

go 

SET quoted_identifier ON 

go 

-- ============================================= 
-- Author:     
-- Create date: <03-22-2017> 
-- Description:   
-- ============================================= 
ALTER PROCEDURE [dbo].[Sp_bluecard_togreencard] 
  -- Add the parameters for the stored procedure here 
  @ptn_pk INT 
AS 
  BEGIN 
      -- SET NOCOUNT ON added to prevent extra result sets from 
      -- interfering with SELECT statements. 
      SET nocount ON; 

      DECLARE @FirstName                   VARBINARY(max), 
              @MiddleName                  VARBINARY(max), 
              @LastName                    VARBINARY(max), 
              @Sex                         INT, 
              @Status                      BIT, 
              @DeleteFlag                  BIT, 
              @CreateDate                  DATETIME, 
              @UserID                      INT, 
              @message                     VARCHAR(80), 
              @Id                          INT, 
              @PatientFacilityId           VARCHAR(50), 
              @PatientType                 INT, 
              @FacilityId                  VARCHAR(10), 
              @DateOfBirth                 DATETIME, 
              @DobPrecision                INT, 
              @NationalId                  VARCHAR(100), 
              @PatientId                   INT, 
              @ARTStartDate                DATE, 
              @transferIn                  INT, 
              @CCCNumber                   VARCHAR(20), 
              @entryPoint                  INT, 
              @ReferredFrom                INT, 
              @RegistrationDate            DATETIME, 
              @MaritalStatusId             INT, 
              @MaritalStatus               INT, 
              @DistrictName                VARCHAR(50), 
              @CountyID                    INT, 
              @SubCountyID                 INT, 
              @WardID                      INT, 
              @Address                     VARBINARY(max), 
              @Phone                       VARBINARY(max), 
              @EnrollmentId                INT, 
              @PatientIdentifierId         INT, 
              @ServiceEntryPointId         INT, 
              @PatientMaritalStatusID      INT, 
              @PatientTreatmentSupporterID INT, 
              @PersonContactID             INT, 
              @IDNational                  VARBINARY(max); 
      DECLARE @FirstNameT                VARCHAR(50), 
              @LastNameT                 VARCHAR(50), 
              @TreatmentSupportTelNumber VARBINARY(max), 
              @CreateDateT               DATETIME, 
              @UserIDT                   INT, 
              @IDT                       INT; 
      DECLARE @TreatmentSupportTelNumber_VARCHAR VARCHAR(100); 

      --PRINT '-------- Patients Report --------';  
      --SELECT @message = '----- ptn_pk ' + CAST(@ptn_pk as varchar(50)); 
      --PRINT @message; 
      --DECLARE mstPatient_cursor CURSOR FOR    
      SELECT TOP 1 @FirstName = firstname, 
                   @MiddleName = middlename, 
                   @LastName = lastname, 
                   @Sex = sex, 
                   @Status = [status], 
                   @DeleteFlag = deleteflag, 
                   @CreateDate = dbo.mst_patient.createdate, 
                   @UserId = dbo.mst_patient.userid, 
                   @PatientFacilityId = patientfacilityid, 
                   @FacilityId = posid, 
                   @DateOfBirth = dob, 
                   @DobPrecision = dobprecision, 
                   @NationalId = [id/passportno], 
                   @CCCNumber = patientenrollmentid, 
                   @ReferredFrom = [referredfrom], 
                   @RegistrationDate = [registrationdate], 
                   @MaritalStatus = maritalstatus, 
                   @DistrictName = districtname, 
                   @Address = [address], 
                   @Phone = phone 
      FROM   mst_patient 
             INNER JOIN dbo.lnk_patientprogramstart 
                     ON dbo.mst_patient.ptn_pk = 
                        dbo.lnk_patientprogramstart.ptn_pk 
      WHERE  ( dbo.lnk_patientprogramstart.moduleid = 203 ) 
             AND dbo.mst_patient.ptn_pk = @ptn_pk 

      --OPEN mstPatient_cursor   
      --FETCH NEXT FROM mstPatient_cursor    
      --INTO @FirstName, @MiddleName, @LastName, @Sex, @Status, @DeleteFlag, @CreateDate, @UserID, @PatientFacilityId, @FacilityId, @DateOfBirth, @DobPrecision, @NationalId,@CCCNumber, @ReferredFrom, @RegistrationDate, @MaritalStatus , @DistrictName, @Address, @Phone
      IF @@rowcount = 1 
        BEGIN 
            --PRINT ' '   
            --SELECT @message = '----- patients From mst_patient: ' + CAST(@ptn_pk as varchar(50)) 
            --PRINT @message   
            EXEC Pr_opendecryptedsession; 

            --set null dates 
            SELECT @CreateDate = Isnull(@CreateDate, Getdate()), 
                   @Status = CASE 
                               WHEN @Status = 1 THEN 0 
                               ELSE 1 
                             END, 
                   @IDNational = Encryptbykey(Key_guid('Key_CTC'), 
                                 Isnull(@NationalId, '99999999')); 

            SET @Sex = (SELECT TOP 1 itemid 
                        FROM   lookupitemview 
                        WHERE  mastername = 'Gender' 
                               AND itemname = (SELECT TOP 1 NAME 
                                               FROM   mst_decode 
                                               WHERE  id = @Sex)); 

            IF @Sex IS NULL 
              SET @Sex = (SELECT TOP 1 itemid 
                          FROM   lookupitemview 
                          WHERE  mastername = 'Unknown' 
                                 AND itemname = 'Unknown'); 

            SET @PatientType=(SELECT TOP 1 id 
                              FROM   lookupitem 
                              WHERE  NAME = 'New'); 
            SET @transferIn=0; 
            --Default all persons to new 
            SET @ARTStartDate=(SELECT TOP 1 arttransferindate 
                               FROM   dtl_patienthivprevcareie 
                               WHERE  ptn_pk = @ptn_pk); 

            IF( @ARTStartDate IS NULL 
                 OR @ARTStartDate = '1900-01-01 00:00:00.000' ) 
              BEGIN 
                  SET @PatientType=(SELECT TOP 1 id 
                                    FROM   lookupitem 
                                    WHERE  NAME = 'New'); 
                  SET @transferIn=0; 
              END 
			ELSE
				BEGIN
					SET @PatientType=(SELECT TOP 1 id 
									  FROM   lookupitem 
									  WHERE  NAME = 'Transfer-In'); 
					SET @transferIn=1; 
				END
        END 

      -- SELECT @PatientType = 1285 
      --encrypt nationalid 
      --SET @IDNational=ENCRYPTBYKEY(KEY_GUID('Key_CTC'),@IDNational); 
      IF NOT EXISTS (SELECT TOP 1 ptn_pk 
                     FROM   patient 
                     WHERE  ptn_pk = @ptn_pk) 
        BEGIN 
            INSERT INTO person 
                        (firstname, 
                         midname, 
                         lastname, 
                         sex, 
                         active, 
                         deleteflag, 
                         createdate, 
                         createdby) 
            VALUES     (@FirstName, 
                        @MiddleName, 
                        @LastName, 
                        @Sex, 
                        @Status, 
                        @DeleteFlag, 
                        @CreateDate, 
                        @UserID); 

            SELECT @Id = Scope_identity(); 

            --SELECT @message = 'Created Person Id: ' + CAST(@Id as varchar(50)); 
            --PRINT @message; 
            INSERT INTO patient 
                        (ptn_pk, 
                         personid, 
                         patientindex, 
                         patienttype, 
                         facilityid, 
                         active, 
                         dateofbirth, 
                         dobprecision, 
                         nationalid, 
                         deleteflag, 
                         createdby, 
                         createdate, 
                         registrationdate) 
            VALUES     (@ptn_pk, 
                        @Id, 
                        @PatientFacilityId, 
                        @PatientType, 
                        @FacilityId, 
                        @Status, 
                        @DateOfBirth, 
                        @DobPrecision, 
                        @IDNational, 
                        @DeleteFlag, 
                        @UserID, 
                        @CreateDate, 
                        @RegistrationDate); 

            SELECT @PatientId = Scope_identity(); 

            --SELECT @message = 'Created Patient Id: ' + CAST(@PatientId as varchar); 
            --PRINT @message; 
            UPDATE mst_patient 
            SET    movedtopatienttable = 1 
            WHERE  ptn_pk = @ptn_pk; 

            INSERT INTO [dbo].[greencardbluecard_transactional] 
                        ([personid], 
                         [ptn_pk]) 
            VALUES      (@Id, 
                         @ptn_pk); 

            -- Insert to PatientEnrollment 
            INSERT INTO [dbo].[patientenrollment] 
                        ([patientid], 
                         [serviceareaid], 
                         [enrollmentdate], 
                         [enrollmentstatusid], 
                         [transferin], 
                         [careended], 
                         [deleteflag], 
                         [createdby], 
                         [createdate], 
                         [auditdata]) 
            VALUES      (@PatientId, 
                         1, 
                         (SELECT TOP 1 startdate 
                          FROM   lnk_patientprogramstart 
                          WHERE  ptn_pk = @ptn_pk), 
                         0, 
                         @transferIn, 
                         0, 
                         0, 
                         @UserID, 
                         @CreateDate, 
                         NULL) 

            SELECT @EnrollmentId = Scope_identity(); 

            --SELECT @message = 'Created PatientEnrollment Id: ' + CAST(@EnrollmentId as varchar); 
            --PRINT @message; 
            IF @CCCNumber IS NOT NULL 
              BEGIN 
                  -- Patient Identifier 
                  INSERT INTO [dbo].[patientidentifier] 
                              ([patientid], 
                               [patientenrollmentid], 
                               [identifiertypeid], 
                               [identifiervalue], 
                               [deleteflag], 
                               [createdby], 
                               [createdate], 
                               [active], 
                               [auditdata]) 
                  VALUES      (@PatientId, 
                               @EnrollmentId, 
                               (SELECT TOP 1 id 
                                FROM   identifiers 
                                WHERE  code = 'CCCNumber'), 
                               @CCCNumber, 
                               0, 
                               @UserID, 
                               @CreateDate, 
                               0, 
                               NULL); 

                  SELECT @PatientIdentifierId = Scope_identity(); 
              --SELECT @message = 'Created PatientIdentifier Id: ' + CAST(@PatientIdentifierId as varchar); 
              --PRINT @message; 
              END 

            --Insert into ServiceEntryPoint 
            IF @ReferredFrom > 0 
              SET @entryPoint = (SELECT TOP 1 itemid 
                                 FROM   [dbo].[lookupitemview] 
                                 WHERE  itemname LIKE '%' 
                                                      + 
                                        (SELECT NAME 
                                         FROM   mst_decode 
                                         WHERE  id = @ReferredFrom 
                                                AND codeid = 17) 
                                                      + '%'); 

            IF @entryPoint IS NULL 
              BEGIN 
                  SET @entryPoint = (SELECT itemid 
                                     FROM   lookupitemview 
                                     WHERE  mastername = 'Unknown' 
                                            AND itemname = 'Unknown'); 
              END 
            ELSE 
              SET @entryPoint = (SELECT itemid 
                                 FROM   lookupitemview 
                                 WHERE  mastername = 'Unknown' 
                                        AND itemname = 'Unknown'); 

            INSERT INTO serviceentrypoint 
                        ([patientid], 
                         [serviceareaid], 
                         [entrypointid], 
                         [deleteflag], 
                         [createdby], 
                         [createdate], 
                         [active]) 
            VALUES     (@PatientId, 
                        1, 
                        @entryPoint, 
                        0, 
                        @UserID, 
                        @CreateDate, 
                        0); 

            SELECT @ServiceEntryPointId = Scope_identity(); 

            --SELECT @message = 'Created ServiceEntryPoint Id: ' + CAST(@ServiceEntryPointId as varchar); 
            --PRINT @message; 
            --Insert into MaritalStatus 
            IF @MaritalStatus > 0 
              BEGIN 
                  IF EXISTS (SELECT TOP 1 itemid 
                             FROM   [dbo].[lookupitemview] 
                             WHERE  itemname LIKE '%' 
                                                  + (SELECT NAME 
                                                     FROM   mst_decode 
                                                     WHERE  id = @MaritalStatus 
                                                            AND codeid = 12) 
                                                  + '%') 
                    SET @MaritalStatusId = (SELECT TOP 1 itemid 
                                            FROM   [dbo].[lookupitemview] 
                                            WHERE  itemname LIKE '%' 
                                                                 + 
                                                   (SELECT NAME 
                                                    FROM   mst_decode 
                                                    WHERE  id = @MaritalStatus 
                                                           AND codeid = 12) 
                                                                 + '%'); 
                  ELSE 
                    SET @MaritalStatusId = (SELECT itemid 
                                            FROM   lookupitemview 
                                            WHERE  mastername = 'Unknown' 
                                                   AND itemname = 'Unknown'); 
              END 
            ELSE 
              SET @MaritalStatusId = (SELECT itemid 
                                      FROM   lookupitemview 
                                      WHERE  mastername = 'Unknown' 
                                             AND itemname = 'Unknown'); 

            INSERT INTO patientmaritalstatus 
                        (personid, 
                         maritalstatusid, 
                         active, 
                         deleteflag, 
                         createdby, 
                         createdate) 
            VALUES     (@Id, 
                        @MaritalStatusId, 
                        1, 
                        0, 
                        @UserID, 
                        @CreateDate); 

            SELECT @PatientMaritalStatusID = Scope_identity(); 

            --SELECT @message = 'Created PatientMaritalStatus Id: ' + CAST(@PatientMaritalStatusID as varchar);
            --PRINT @message; 
            --Insert into PersonLocation 
            ----SET @CountyID = (SELECT TOP 1 CountyId from County where CountyName like '%' + @DistrictName  + '%');
            ----SET @WardID = (SELECT TOP 1 WardId FROM County WHERE WardName LIKE '%' +  +'%')
            ----INSERT INTO PersonLocation(PersonId, County, SubCounty, Ward, Village, Location, SubLocation, LandMark, NearestHealthCentre, Active, DeleteFlag, CreatedBy, CreateDate)
            ----VALUES(@Id, @CountyID, @SubCountyID, @WardID, @Village, @Location, @SubLocation, @LandMark, @NearestHealthCentre, 1, @DeleteFlag, @UserID, @CreateDate);
            --Insert into Treatment Supporter 
            --DECLARE Treatment_Supporter_cursor CURSOR FOR 
            SELECT TOP 1 @FirstNameT = Substring(treatmentsupportername, 0, 
                                                    Charindex(' ', 
                                                    treatmentsupportername)) 
                         --                    As firstname 
                         , 
                         @LastNameT = Substring(treatmentsupportername, 
                                      Charindex(' ', treatmentsupportername) + 1 
                                      , 
                                                   Len(treatmentsupportername) + 
                                                   1 
                                      ) 
                         --As lastname 
                         , 
                         @TreatmentSupportTelNumber_VARCHAR = 
                         treatmentsupporttelnumber, 
                         @CreateDateT = createdate, 
                         @UserIDT = userid 
            FROM   dtl_patientcontacts 
            WHERE  ptn_pk = @ptn_pk 
                   AND NULLIF(treatmentsupportname, '') IS NOT NULL; 

            --OPEN Treatment_Supporter_cursor 
            --FETCH NEXT FROM Treatment_Supporter_cursor INTO @FirstNameT, @LastNameT, @TreatmentSupportTelNumber_VARCHAR, @CreateDateT , @UserIDT
            --IF @@FETCH_STATUS <> 0    
            --  PRINT '         <>'        
            IF @@rowcount = 1 
              BEGIN 
                  --SELECT @message = '         ' + @product   
                  --PRINT @message 
                  --SET @TreatmentSupportTelNumber = ENCRYPTBYKEY(KEY_GUID('Key_CTC'),@TreatmentSupportTelNumber_VARCHAR);
                  IF @FirstNameT IS NOT NULL 
                     AND @LastNameT IS NOT NULL 
                    BEGIN 
                        INSERT INTO person 
                                    (firstname, 
                                     midname, 
                                     lastname, 
                                     sex, 
                                     active, 
                                     deleteflag, 
                                     createdate, 
                                     createdby) 
                        VALUES     (Encryptbykey(Key_guid('Key_CTC'), 
                                    @FirstNameT) 
                                    , 
                                    NULL, 
                                    Encryptbykey(Key_guid('Key_CTC'), @LastNameT 
                                    ), 
                                    (SELECT itemid 
                                     FROM   lookupitemview 
                                     WHERE  mastername = 'Unknown' 
                                            AND itemname = 'Unknown'), 
                                    1, 
                                    0, 
                                    @CreateDateT, 
                                    @UserIDT); 

                        SELECT @IDT = Scope_identity(); 

                        --SELECT @message = 'Created Person Treatment Supporter Id: ' + CAST(@IDT as varchar(50)); 
                        --PRINT @message; 
                        IF @TreatmentSupportTelNumber_VARCHAR IS NOT NULL 
                          SET @TreatmentSupportTelNumber = 
                          Encryptbykey(Key_guid('Key_CTC'), 
                          @TreatmentSupportTelNumber_VARCHAR 
                          ) 

                        INSERT INTO patienttreatmentsupporter 
                                    (personid, 
                                     [supporterid], 
                                     [mobilecontact], 
                                     [deleteflag], 
                                     [createdby], 
                                     [createdate]) 
                        VALUES     (@Id, 
                                    @IDT, 
                                    @TreatmentSupportTelNumber, 
                                    0, 
                                    @UserIDT, 
                                    @CreateDateT); 

                        SELECT @PatientTreatmentSupporterID = Scope_identity(); 
                    --SELECT @message = 'Created PatientTreatmentSupporterID Id: ' + CAST(@PatientTreatmentSupporterID as varchar);
                    --PRINT @message; 
                    END 

                  --  FETCH NEXT FROM Treatment_Supporter_cursor INTO  @FirstNameT, @LastNameT, @TreatmentSupportTelNumber_VARCHAR, @CreateDateT, @UserIDT
                  --  END   
                  --CLOSE Treatment_Supporter_cursor   
                  --DEALLOCATE Treatment_Supporter_cursor 
                  --Insert into Person Contact 
                  IF @Address IS NOT NULL 
                      OR @Phone IS NOT NULL 
                    BEGIN 
                        INSERT INTO personcontact 
                                    (personid, 
                                     [physicaladdress], 
                                     [mobilenumber], 
                                     [alternativenumber], 
                                     [emailaddress], 
                                     [active], 
                                     [deleteflag], 
                                     [createdby], 
                                     [createdate]) 
                        VALUES     (@Id, 
                                    @Address, 
                                    @Phone, 
                                    NULL, 
                                    NULL, 
                                    @Status, 
                                    0, 
                                    @UserID, 
                                    @CreateDate); 

                        SELECT @PersonContactID = Scope_identity(); 
                    --SELECT @message = 'Created PersonContact Id: ' + CAST(@PersonContactID as varchar); 
                    --PRINT @message; 
                    END 
              END 
        END 
      ELSE 
        BEGIN 
            SET @Id = (SELECT TOP 1 personid 
                       FROM   patient 
                       WHERE  ptn_pk = @ptn_pk); 

            UPDATE person 
            SET    firstname = @FirstName, 
                   midname = @MiddleName, 
                   lastname = @LastName, 
                   sex = @Sex, 
                   active = @Status, 
                   deleteflag = @DeleteFlag, 
                   createdate = @CreateDate, 
                   createdby = @UserID 
            WHERE  id = @Id; 

            --SELECT @message = 'Update Person Id: ' + CAST(@Id as varchar(50)); 
            --PRINT @message; 
            --PRINT @Status; 
            UPDATE patient 
            SET    patientindex = @PatientFacilityId, 
                   patienttype = @PatientType, 
                   facilityid = @FacilityId, 
                   active = @Status, 
                   dateofbirth = @DateOfBirth, 
                   dobprecision = @DobPrecision, 
                   nationalid = @IDNational, 
                   deleteflag = @DeleteFlag, 
                   createdby = @UserID, 
                   createdate = @CreateDate, 
                   registrationdate = @RegistrationDate 
            WHERE  personid = @Id; 

            SELECT @PatientId = (SELECT TOP 1 id 
                                 FROM   patient 
                                 WHERE  personid = @Id); 

            --SELECT @message = 'Updated Patient ' +  cast(@PatientId as varchar); 
            --PRINT @message; 
            UPDATE patientenrollment 
            SET    enrollmentdate = (SELECT TOP 1 startdate 
                                     FROM   lnk_patientprogramstart 
                                     WHERE  ptn_pk = @ptn_pk AND moduleId = 203), 
                   enrollmentstatusid = 0, 
                   transferin = @transferIn, 
                   careended = 0, 
                   deleteflag = 0, 
                   createdby = @UserID, 
                   createdate = @CreateDate 
            WHERE  patientid = @PatientId; 

            IF( @@rowcount = 0 ) 
              BEGIN 
                  INSERT INTO [dbo].[patientenrollment] 
                              ([patientid], 
                               [serviceareaid], 
                               [enrollmentdate], 
                               [enrollmentstatusid], 
                               [transferin], 
                               [careended], 
                               [deleteflag], 
                               [createdby], 
                               [createdate], 
                               [auditdata]) 
                  VALUES      (@PatientId, 
                               1, 
                               (SELECT TOP 1 startdate 
                                FROM   lnk_patientprogramstart 
                                WHERE  ptn_pk = @ptn_pk AND ModuleId = 203), 
                               0, 
                               @transferIn, 
                               0, 
                               0, 
                               @UserID, 
                               @CreateDate, 
                               NULL) 
              END 

            SELECT @EnrollmentId = (SELECT TOP 1 id 
                                    FROM   patientenrollment 
                                    WHERE  patientid = @PatientId 
                                           AND serviceareaid = 1); 

            --SELECT @message = 'Updated PatientEnrollment Id: ' + CAST(@EnrollmentId as varchar); 
            --PRINT @message; 
            IF @CCCNumber IS NOT NULL 
              BEGIN 
                  IF NOT EXISTS (SELECT patientid 
                                 FROM   patientidentifier 
                                 WHERE  patientid = @PatientId 
                                        AND patientenrollmentid = @EnrollmentId 
                                        AND identifiertypeid = 
                                            (SELECT TOP 1 id 
                                             FROM   identifiers 
                                             WHERE  code = 'CCCNumber')) 
                    BEGIN 
                        -- Patient Identifier 
                        INSERT INTO [dbo].[patientidentifier] 
                                    ([patientid], 
                                     [patientenrollmentid], 
                                     [identifiertypeid], 
                                     [identifiervalue], 
                                     [deleteflag], 
                                     [createdby], 
                                     [createdate], 
                                     [active], 
                                     [auditdata]) 
                        VALUES      (@PatientId, 
                                     @EnrollmentId, 
                                     (SELECT TOP 1 id 
                                      FROM   identifiers 
                                      WHERE  code = 'CCCNumber'), 
                                     @CCCNumber, 
                                     0, 
                                     @UserID, 
                                     @CreateDate, 
                                     0, 
                                     NULL); 

                        SELECT @PatientIdentifierId = Scope_identity(); 
                    --SELECT @message = 'Created PatientIdentifier Id: ' + CAST(@PatientIdentifierId as varchar); 
                    --PRINT @message; 
                    END                  
					ELSE 
						BEGIN 
							UPDATE patientidentifier 
							SET    identifiertypeid = (SELECT TOP 1 id 
													   FROM   identifiers 
													   WHERE  code = 'CCCNumber'), 
								   identifiervalue = @CCCNumber, 
								   deleteflag = 0, 
								   createdby = @UserID, 
								   createdate = @CreateDate, 
								   active = 0 
							WHERE  patientid = @PatientId 
								   AND patientenrollmentid = @EnrollmentId 
								   AND identifiertypeid = (SELECT id 
														   FROM   Identifiers 
														   WHERE  Code = 'CCCNumber' 
														  ) 
						END					 
              END 

            --Insert into ServiceEntryPoint 
            IF @ReferredFrom > 0 
              BEGIN 
                  SET @entryPoint = (SELECT TOP 1 itemid 
                                     FROM   [dbo].[lookupitemview] 
                                     WHERE  itemname LIKE '%' 
                                                          + 
                                            (SELECT NAME 
                                             FROM   mst_decode 
                                             WHERE  id = @ReferredFrom 
                                                    AND codeid = 17) 
                                                          + '%'); 

                  IF @entryPoint IS NULL 
                    BEGIN 
                        SET @entryPoint = (SELECT TOP 1 itemid 
                                           FROM   lookupitemview 
                                           WHERE  mastername = 'Unknown' 
                                                  AND itemname = 'Unknown'); 
                    END 

                  UPDATE serviceentrypoint 
                  SET    entrypointid = @entryPoint, 
                         createdby = @UserID, 
                         createdate = @CreateDate 
                  WHERE  patientid = @PatientId; 

                  SELECT @ServiceEntryPointId = Scope_identity(); 
              --SELECT @message = 'Updated ServiceEntryPoint Id: ' + CAST(@ServiceEntryPointId as varchar); 
              --PRINT @message; 
              END 

            --Updated into MaritalStatus 
            IF @MaritalStatus > 0 
              BEGIN 
                  BEGIN 
                      IF EXISTS (SELECT TOP 1 itemid 
                                 FROM   [dbo].[lookupitemview] 
                                 WHERE  itemname LIKE '%' 
                                                      + 
                                        (SELECT NAME 
                                         FROM   mst_decode 
                                         WHERE  id = @MaritalStatus 
                                                AND codeid = 12) 
                                                      + '%') 
                        SET @MaritalStatusId = (SELECT TOP 1 itemid 
                                                FROM   [dbo].[lookupitemview] 
                                                WHERE  itemname LIKE '%' 
                                                                     + 
                        (SELECT NAME 
                         FROM   mst_decode 
                         WHERE  id = @MaritalStatus 
                                AND codeid = 12) 
                                      + '%'); 
                      ELSE 
                        SET @MaritalStatusId = (SELECT itemid 
                                                FROM   lookupitemview 
                                                WHERE  mastername = 'Unknown' 
                                                       AND itemname = 'Unknown') 
                      ; 
                  END 

                  UPDATE patientmaritalstatus 
                  SET    maritalstatusid = @MaritalStatusId, 
                         createdby = @UserID, 
                         createdate = @CreateDate 
                  WHERE  personid = @Id; 

                  SELECT @PatientMaritalStatusID = Scope_identity(); 
              --SELECT @message = 'Updated PatientMaritalStatus Id: ' + CAST(@PatientMaritalStatusID as varchar);
              --PRINT @message; 
              END 

            --Update into Treatment Supporter 
            --DECLARE Treatment_Supporter_cursor CURSOR FOR 
            SELECT TOP 1 @FirstNameT = Substring(treatmentsupportername, 0, 
                                                    Charindex(' ', 
                                                    treatmentsupportername)) 
                         --  As firstname 
                         , 
                         @LastNameT = Substring(treatmentsupportername, 
                                      Charindex(' ', treatmentsupportername) + 1 
                                      , 
                                                   Len(treatmentsupportername) + 
                                                   1 
                                      ) 
                         --As lastname 
                         , 
                         @TreatmentSupportTelNumber_VARCHAR = 
                         treatmentsupporttelnumber, 
                         @CreateDateT = createdate, 
                         @UserIDT = userid 
            FROM   dtl_patientcontacts 
            WHERE  ptn_pk = @ptn_pk 
                   AND NULLIF(treatmentsupportername, '') IS NOT NULL; 

            --OPEN Treatment_Supporter_cursor 
            --FETCH NEXT FROM Treatment_Supporter_cursor INTO @FirstNameT, @LastNameT, @TreatmentSupportTelNumber_VARCHAR, @CreateDateT , @UserIDT
            --IF @@FETCH_STATUS <> 0    
            --  PRINT '         <>'        
            --WHILE @@FETCH_STATUS = 0   
            IF( @@rowcount = 1 ) 
              BEGIN 
                  --SET @TreatmentSupportTelNumber = ENCRYPTBYKEY(KEY_GUID('Key_CTC'),@TreatmentSupportTelNumber); 
                  IF @FirstNameT IS NOT NULL 
                     AND @LastNameT IS NOT NULL 
                    BEGIN 
                        IF NOT EXISTS (SELECT personid 
                                       FROM   patienttreatmentsupporter 
                                       WHERE  personid = @Id) 
                          BEGIN 
                              INSERT INTO person 
                                          (firstname, 
                                           midname, 
                                           lastname, 
                                           sex, 
                                           active, 
                                           deleteflag, 
                                           createdate, 
                                           createdby) 
                              VALUES     (Encryptbykey(Key_guid('Key_CTC'), 
                                          @FirstNameT) 
                                          , 
                                          NULL, 
                                          Encryptbykey(Key_guid('Key_CTC'), 
                                          @LastNameT 
                                          ), 
                                          (SELECT itemid 
                                           FROM   lookupitemview 
                                           WHERE  mastername = 'Unknown' 
                                                  AND itemname = 'Unknown'), 
                                          1, 
                                          0, 
                                          Getdate(), 
                                          @UserIDT); 

                              SELECT @IDT = Scope_identity(); 

                              --SELECT @message = 'Created Person Treatment Supporter Id: ' + CAST(@IDT as varchar(50)); 
                              --PRINT @message; 
                              IF @TreatmentSupportTelNumber_VARCHAR IS NOT NULL 
                                SET @TreatmentSupportTelNumber = 
                                Encryptbykey(Key_guid('Key_CTC'), 
                                @TreatmentSupportTelNumber_VARCHAR 
                                ) 

                              INSERT INTO patienttreatmentsupporter 
                                          (personid, 
                                           [supporterid], 
                                           [mobilecontact], 
                                           [deleteflag], 
                                           [createdby], 
                                           [createdate]) 
                              VALUES     (@Id, 
                                          @IDT, 
                                          @TreatmentSupportTelNumber, 
                                          0, 
                                          @UserIDT, 
                                          Getdate()); 
                          END 
                        ELSE 
                          BEGIN 
                              SET @IDT = (SELECT supporterid 
                                          FROM   patienttreatmentsupporter 
                                          WHERE  personid = @Id); 

                              UPDATE person 
                              SET    firstname = Encryptbykey(Key_guid('Key_CTC' 
                                                              ), 
                                                 @FirstNameT 
                                                 ), 
                                     lastname = Encryptbykey(Key_guid('Key_CTC') 
                                                , 
                                                @LastNameT 
                                                ) 
                              WHERE  id = @IDT; 

                              IF @TreatmentSupportTelNumber_VARCHAR IS NOT NULL 
                                SET @TreatmentSupportTelNumber = 
                                Encryptbykey(Key_guid('Key_CTC'), 
                                @TreatmentSupportTelNumber_VARCHAR 
                                ) 

                              UPDATE patienttreatmentsupporter 
                              SET    mobilecontact = @TreatmentSupportTelNumber 
                              WHERE  personid = @Id; 
                          END 
                    END 
              --FETCH NEXT FROM Treatment_Supporter_cursor INTO  @FirstNameT, @LastNameT, @TreatmentSupportTelNumber_VARCHAR, @CreateDateT, @UserIDT
              END 

            --CLOSE Treatment_Supporter_cursor   
            --DEALLOCATE Treatment_Supporter_cursor 
            --UPDATE into Person Contact 
            IF @Address IS NOT NULL 
                OR @Phone IS NOT NULL 
              BEGIN 
                  UPDATE personcontact 
                  SET    physicaladdress = Isnull(@Address, physicaladdress), 
                         mobilenumber = Isnull(@Phone, mobilenumber) 
                  WHERE  personid = @Id; 

                  IF @@rowcount = 0 
                    BEGIN 
                        INSERT INTO personcontact 
                                    (personid, 
                                     [physicaladdress], 
                                     [mobilenumber], 
                                     [alternativenumber], 
                                     [emailaddress], 
                                     [active], 
                                     [deleteflag], 
                                     [createdby], 
                                     [createdate]) 
                        VALUES     (@Id, 
                                    @Address, 
                                    @Phone, 
                                    NULL, 
                                    NULL, 
                                    @Status, 
                                    0, 
                                    @UserID, 
                                    @CreateDate); 
                    END 
              END 
        END 
  -- Get the next mst_patient. 
  --  FETCH NEXT FROM mstPatient_cursor    
  -- INTO @FirstName, @MiddleName, @LastName, @Sex, @Status, @DeleteFlag, @CreateDate, @UserID, @PatientFacilityId, @FacilityId, @DateOfBirth, @DobPrecision, @NationalId, @CCCNumber, @ReferredFrom, @RegistrationDate, @MaritalStatus , @DistrictName, @Address, @Phone
  END 
--CLOSE mstPatient_cursor;   
--DEALLOCATE mstPatient_cursor;   