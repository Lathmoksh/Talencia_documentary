-- =============================================================
-- Talentra Enterprise Workforce Platform: Foreign Keys, Indexes & RLS
-- Engine: PostgreSQL 16 Enterprise
-- =============================================================

-- -------------------------------------------------------------
-- GIST EXCLUSION CONSTRAINTS (Rule Group 9, 10 & Backlog B35, B47)
-- -------------------------------------------------------------
-- Backlog B35: Gig windows cannot overlap for the same gig worker
ALTER TABLE gig.gig_worker_availability 
    ADD CONSTRAINT excl_gig_worker_avail_overlap 
    EXCLUDE USING gist (worker_id WITH =, availability_window WITH &&);

-- Rule Group 10 & Backlog B47: Subscription periods must not overlap for the same licence/account
ALTER TABLE licensing.subscription_licence 
    ADD CONSTRAINT excl_subscription_licence_overlap 
    EXCLUDE USING gist (account_id WITH =, validity_period WITH &&);

-- -------------------------------------------------------------
-- FOREIGN KEY CONSTRAINTS
-- -------------------------------------------------------------
ALTER TABLE master_data.country ADD CONSTRAINT fk_country_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE master_data.country ADD CONSTRAINT fk_country_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.country ADD CONSTRAINT fk_country_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.state ADD CONSTRAINT fk_state_country_id FOREIGN KEY (country_id) REFERENCES master_data.country (id) ON DELETE RESTRICT;
ALTER TABLE master_data.state ADD CONSTRAINT fk_state_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.state ADD CONSTRAINT fk_state_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.city ADD CONSTRAINT fk_city_country_id FOREIGN KEY (country_id) REFERENCES master_data.country (id) ON DELETE RESTRICT;
ALTER TABLE master_data.city ADD CONSTRAINT fk_city_state_id FOREIGN KEY (state_id) REFERENCES master_data.state (id) ON DELETE RESTRICT;
ALTER TABLE master_data.city ADD CONSTRAINT fk_city_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.city ADD CONSTRAINT fk_city_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.currency ADD CONSTRAINT fk_currency_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.currency ADD CONSTRAINT fk_currency_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.language ADD CONSTRAINT fk_language_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.language ADD CONSTRAINT fk_language_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.industry ADD CONSTRAINT fk_industry_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.industry ADD CONSTRAINT fk_industry_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.job_role ADD CONSTRAINT fk_job_role_industry_id FOREIGN KEY (industry_id) REFERENCES master_data.industry (id) ON DELETE RESTRICT;
ALTER TABLE master_data.job_role ADD CONSTRAINT fk_job_role_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.job_role ADD CONSTRAINT fk_job_role_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.skill ADD CONSTRAINT fk_skill_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.skill ADD CONSTRAINT fk_skill_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.qualification ADD CONSTRAINT fk_qualification_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.qualification ADD CONSTRAINT fk_qualification_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation_key ADD CONSTRAINT fk_ui_translation_key_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation_key ADD CONSTRAINT fk_ui_translation_key_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation ADD CONSTRAINT fk_ui_translation_key_id FOREIGN KEY (key_id) REFERENCES master_data.ui_translation_key (id) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation ADD CONSTRAINT fk_ui_translation_language_code FOREIGN KEY (language_code) REFERENCES master_data.language (language_code) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation ADD CONSTRAINT fk_ui_translation_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.ui_translation ADD CONSTRAINT fk_ui_translation_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_account ADD CONSTRAINT fk_user_account_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_credential ADD CONSTRAINT fk_user_credential_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_credential ADD CONSTRAINT fk_user_credential_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_credential ADD CONSTRAINT fk_user_credential_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.role ADD CONSTRAINT fk_role_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.role ADD CONSTRAINT fk_role_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_role_id FOREIGN KEY (role_id) REFERENCES identity.role (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_granted_by FOREIGN KEY (granted_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_role ADD CONSTRAINT fk_user_role_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_active_session ADD CONSTRAINT fk_user_active_session_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_active_session ADD CONSTRAINT fk_user_active_session_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.user_active_session ADD CONSTRAINT fk_user_active_session_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.service_api_key ADD CONSTRAINT fk_service_api_key_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.service_api_key ADD CONSTRAINT fk_service_api_key_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE identity.service_api_key ADD CONSTRAINT fk_service_api_key_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.account ADD CONSTRAINT fk_account_billing_currency_code FOREIGN KEY (billing_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE organisation.account ADD CONSTRAINT fk_account_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.account ADD CONSTRAINT fk_account_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_account_id FOREIGN KEY (account_id) REFERENCES organisation.account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_industry_id FOREIGN KEY (industry_id) REFERENCES master_data.industry (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation ADD CONSTRAINT fk_organisation_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_city_id FOREIGN KEY (city_id) REFERENCES master_data.city (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_state_id FOREIGN KEY (state_id) REFERENCES master_data.state (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_country_id FOREIGN KEY (country_id) REFERENCES master_data.country (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_location ADD CONSTRAINT fk_organisation_location_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_tax_identifier ADD CONSTRAINT fk_organisation_tax_identifier_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_tax_identifier ADD CONSTRAINT fk_organisation_tax_identifier_country_id FOREIGN KEY (country_id) REFERENCES master_data.country (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_tax_identifier ADD CONSTRAINT fk_organisation_tax_identifier_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_tax_identifier ADD CONSTRAINT fk_organisation_tax_identifier_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_verification ADD CONSTRAINT fk_organisation_verification_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_verification ADD CONSTRAINT fk_organisation_verification_verified_by FOREIGN KEY (verified_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_verification ADD CONSTRAINT fk_organisation_verification_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_verification ADD CONSTRAINT fk_organisation_verification_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.recruiter_seat_assignment ADD CONSTRAINT fk_recruiter_seat_assignment_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE organisation.recruiter_seat_assignment ADD CONSTRAINT fk_recruiter_seat_assignment_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.recruiter_seat_assignment ADD CONSTRAINT fk_recruiter_seat_assignment_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.recruiter_seat_assignment ADD CONSTRAINT fk_recruiter_seat_assignment_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_hierarchy ADD CONSTRAINT fk_organisation_hierarchy_parent_organisation_id FOREIGN KEY (parent_organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_hierarchy ADD CONSTRAINT fk_organisation_hierarchy_child_organisation_id FOREIGN KEY (child_organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_hierarchy ADD CONSTRAINT fk_organisation_hierarchy_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE organisation.organisation_hierarchy ADD CONSTRAINT fk_organisation_hierarchy_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_current_city_id FOREIGN KEY (current_city_id) REFERENCES master_data.city (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_profile ADD CONSTRAINT fk_candidate_profile_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_education ADD CONSTRAINT fk_candidate_education_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_education ADD CONSTRAINT fk_candidate_education_qualification_id FOREIGN KEY (qualification_id) REFERENCES master_data.qualification (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_education ADD CONSTRAINT fk_candidate_education_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_education ADD CONSTRAINT fk_candidate_education_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_job_role_id FOREIGN KEY (job_role_id) REFERENCES master_data.job_role (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_industry_id FOREIGN KEY (industry_id) REFERENCES master_data.industry (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_work_experience ADD CONSTRAINT fk_candidate_work_experience_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_skill ADD CONSTRAINT fk_candidate_skill_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_skill ADD CONSTRAINT fk_candidate_skill_skill_id FOREIGN KEY (skill_id) REFERENCES master_data.skill (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_skill ADD CONSTRAINT fk_candidate_skill_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_skill ADD CONSTRAINT fk_candidate_skill_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_project ADD CONSTRAINT fk_candidate_project_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_project ADD CONSTRAINT fk_candidate_project_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_project ADD CONSTRAINT fk_candidate_project_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_resume ADD CONSTRAINT fk_candidate_resume_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_resume ADD CONSTRAINT fk_candidate_resume_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_resume ADD CONSTRAINT fk_candidate_resume_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE candidate.candidate_preference ADD CONSTRAINT fk_candidate_preference_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_preference ADD CONSTRAINT fk_candidate_preference_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_preference ADD CONSTRAINT fk_candidate_preference_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_blocked_organisation_id FOREIGN KEY (blocked_organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_blocked_recruiter_user_id FOREIGN KEY (blocked_recruiter_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_block_list ADD CONSTRAINT fk_candidate_block_list_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_language ADD CONSTRAINT fk_candidate_language_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_language ADD CONSTRAINT fk_candidate_language_language_code FOREIGN KEY (language_code) REFERENCES master_data.language (language_code) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_language ADD CONSTRAINT fk_candidate_language_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE candidate.candidate_language ADD CONSTRAINT fk_candidate_language_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_posted_by_user_id FOREIGN KEY (posted_by_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_job_role_id FOREIGN KEY (job_role_id) REFERENCES master_data.job_role (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_city_id FOREIGN KEY (city_id) REFERENCES master_data.city (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition ADD CONSTRAINT fk_job_requisition_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition_skill ADD CONSTRAINT fk_job_requisition_skill_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition_skill ADD CONSTRAINT fk_job_requisition_skill_skill_id FOREIGN KEY (skill_id) REFERENCES master_data.skill (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition_skill ADD CONSTRAINT fk_job_requisition_skill_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_requisition_skill ADD CONSTRAINT fk_job_requisition_skill_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_questionnaire ADD CONSTRAINT fk_job_questionnaire_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_questionnaire ADD CONSTRAINT fk_job_questionnaire_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.job_questionnaire ADD CONSTRAINT fk_job_questionnaire_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.questionnaire_question ADD CONSTRAINT fk_questionnaire_question_questionnaire_id FOREIGN KEY (questionnaire_id) REFERENCES recruitment.job_questionnaire (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.questionnaire_question ADD CONSTRAINT fk_questionnaire_question_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.questionnaire_question ADD CONSTRAINT fk_questionnaire_question_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE recruitment.question_option ADD CONSTRAINT fk_question_option_question_id FOREIGN KEY (question_id) REFERENCES recruitment.questionnaire_question (id) ON DELETE CASCADE;
ALTER TABLE recruitment.question_option ADD CONSTRAINT fk_question_option_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE recruitment.question_option ADD CONSTRAINT fk_question_option_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition (id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_resume_id FOREIGN KEY (resume_id) REFERENCES candidate.candidate_resume (id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_consultant_id FOREIGN KEY (consultant_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.job_application ADD CONSTRAINT fk_job_application_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.application_question_answer ADD CONSTRAINT fk_application_question_answer_question_id FOREIGN KEY (question_id) REFERENCES recruitment.questionnaire_question (id) ON DELETE RESTRICT;
ALTER TABLE application.application_question_answer ADD CONSTRAINT fk_application_question_answer_selected_option_id FOREIGN KEY (selected_option_id) REFERENCES recruitment.question_option (id) ON DELETE RESTRICT;
ALTER TABLE application.application_question_answer ADD CONSTRAINT fk_application_question_answer_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.application_question_answer ADD CONSTRAINT fk_application_question_answer_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.application_stage_history ADD CONSTRAINT fk_application_stage_history_changed_by_user_id FOREIGN KEY (changed_by_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.application_stage_history ADD CONSTRAINT fk_application_stage_history_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.job_interview ADD CONSTRAINT fk_job_interview_interviewer_user_id FOREIGN KEY (interviewer_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.job_interview ADD CONSTRAINT fk_job_interview_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.job_interview ADD CONSTRAINT fk_job_interview_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.interview_feedback ADD CONSTRAINT fk_interview_feedback_interview_id FOREIGN KEY (interview_id) REFERENCES application.job_interview (id) ON DELETE CASCADE;
ALTER TABLE application.interview_feedback ADD CONSTRAINT fk_interview_feedback_interviewer_user_id FOREIGN KEY (interviewer_user_id) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE application.interview_feedback ADD CONSTRAINT fk_interview_feedback_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE application.interview_feedback ADD CONSTRAINT fk_interview_feedback_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE application.job_offer ADD CONSTRAINT fk_job_offer_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE application.job_offer ADD CONSTRAINT fk_job_offer_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE application.job_offer ADD CONSTRAINT fk_job_offer_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_consultant_user_id FOREIGN KEY (consultant_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_authorized_by_user_id FOREIGN KEY (authorized_by_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.consultant_authorization ADD CONSTRAINT fk_consultant_authorization_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.candidate_nomination ADD CONSTRAINT fk_candidate_nomination_authorization_id FOREIGN KEY (authorization_id) REFERENCES sourcing.consultant_authorization (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.candidate_nomination ADD CONSTRAINT fk_candidate_nomination_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.candidate_nomination ADD CONSTRAINT fk_candidate_nomination_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.candidate_nomination ADD CONSTRAINT fk_candidate_nomination_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_campaign ADD CONSTRAINT fk_outreach_campaign_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_campaign ADD CONSTRAINT fk_outreach_campaign_created_by_user_id FOREIGN KEY (created_by_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_campaign ADD CONSTRAINT fk_outreach_campaign_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_campaign ADD CONSTRAINT fk_outreach_campaign_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_recipient ADD CONSTRAINT fk_outreach_recipient_campaign_id FOREIGN KEY (campaign_id) REFERENCES sourcing.outreach_campaign (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_recipient ADD CONSTRAINT fk_outreach_recipient_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_recipient ADD CONSTRAINT fk_outreach_recipient_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE sourcing.outreach_recipient ADD CONSTRAINT fk_outreach_recipient_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_profile ADD CONSTRAINT fk_gig_worker_profile_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_profile ADD CONSTRAINT fk_gig_worker_profile_rate_currency_code FOREIGN KEY (rate_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_profile ADD CONSTRAINT fk_gig_worker_profile_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_profile ADD CONSTRAINT fk_gig_worker_profile_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_service_category_id FOREIGN KEY (service_category_id) REFERENCES master_data.industry (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_price_currency_code FOREIGN KEY (price_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_service ADD CONSTRAINT fk_gig_worker_service_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_availability ADD CONSTRAINT fk_gig_worker_availability_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_availability ADD CONSTRAINT fk_gig_worker_availability_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_worker_availability ADD CONSTRAINT fk_gig_worker_availability_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_posted_by_user_id FOREIGN KEY (posted_by_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_project_category_id FOREIGN KEY (project_category_id) REFERENCES master_data.industry (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_budget_currency_code FOREIGN KEY (budget_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_request ADD CONSTRAINT fk_gig_request_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_request_id FOREIGN KEY (request_id) REFERENCES gig.gig_request (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_proposed_currency_code FOREIGN KEY (proposed_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_proposal ADD CONSTRAINT fk_gig_proposal_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_request_id FOREIGN KEY (request_id) REFERENCES gig.gig_request (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_proposal_id FOREIGN KEY (proposal_id) REFERENCES gig.gig_proposal (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_contract ADD CONSTRAINT fk_gig_contract_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_milestone ADD CONSTRAINT fk_gig_milestone_contract_id FOREIGN KEY (contract_id) REFERENCES gig.gig_contract (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_milestone ADD CONSTRAINT fk_gig_milestone_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE gig.gig_milestone ADD CONSTRAINT fk_gig_milestone_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_milestone ADD CONSTRAINT fk_gig_milestone_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_contract_id FOREIGN KEY (contract_id) REFERENCES gig.gig_contract (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_rater_user_id FOREIGN KEY (rater_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_rated_user_id FOREIGN KEY (rated_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.gig_rating ADD CONSTRAINT fk_gig_rating_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.client_gig_worker_preference ADD CONSTRAINT fk_client_gig_worker_preference_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE gig.client_gig_worker_preference ADD CONSTRAINT fk_client_gig_worker_preference_worker_id FOREIGN KEY (worker_id) REFERENCES gig.gig_worker_profile (id) ON DELETE RESTRICT;
ALTER TABLE gig.client_gig_worker_preference ADD CONSTRAINT fk_client_gig_worker_preference_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE gig.client_gig_worker_preference ADD CONSTRAINT fk_client_gig_worker_preference_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_plan ADD CONSTRAINT fk_subscription_plan_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_plan ADD CONSTRAINT fk_subscription_plan_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_plan ADD CONSTRAINT fk_subscription_plan_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_licence ADD CONSTRAINT fk_subscription_licence_account_id FOREIGN KEY (account_id) REFERENCES organisation.account (id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_licence ADD CONSTRAINT fk_subscription_licence_plan_id FOREIGN KEY (plan_id) REFERENCES licensing.subscription_plan (id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_licence ADD CONSTRAINT fk_subscription_licence_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE licensing.subscription_licence ADD CONSTRAINT fk_subscription_licence_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE licensing.licence_entitlement_usage ADD CONSTRAINT fk_licence_entitlement_usage_licence_id FOREIGN KEY (licence_id) REFERENCES licensing.subscription_licence (id) ON DELETE RESTRICT;
ALTER TABLE licensing.licence_entitlement_usage ADD CONSTRAINT fk_licence_entitlement_usage_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE licensing.licence_entitlement_usage ADD CONSTRAINT fk_licence_entitlement_usage_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_account ADD CONSTRAINT fk_wallet_account_account_id FOREIGN KEY (account_id) REFERENCES organisation.account (id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_account ADD CONSTRAINT fk_wallet_account_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_account ADD CONSTRAINT fk_wallet_account_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_account ADD CONSTRAINT fk_wallet_account_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_ledger ADD CONSTRAINT fk_wallet_ledger_wallet_id FOREIGN KEY (wallet_id) REFERENCES billing.wallet_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_ledger ADD CONSTRAINT fk_wallet_ledger_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.wallet_ledger ADD CONSTRAINT fk_wallet_ledger_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_order ADD CONSTRAINT fk_payment_order_account_id FOREIGN KEY (account_id) REFERENCES organisation.account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_order ADD CONSTRAINT fk_payment_order_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.payment_order ADD CONSTRAINT fk_payment_order_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_order ADD CONSTRAINT fk_payment_order_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_order_id FOREIGN KEY (order_id) REFERENCES billing.payment_order (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_wallet_id FOREIGN KEY (wallet_id) REFERENCES billing.wallet_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_transaction ADD CONSTRAINT fk_payment_transaction_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_gateway_event ADD CONSTRAINT fk_payment_gateway_event_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.payment_gateway_event ADD CONSTRAINT fk_payment_gateway_event_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_account_id FOREIGN KEY (account_id) REFERENCES organisation.account (id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_order_id FOREIGN KEY (order_id) REFERENCES billing.payment_order (id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice ADD CONSTRAINT fk_invoice_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.invoice_item ADD CONSTRAINT fk_invoice_item_invoice_id FOREIGN KEY (invoice_id) REFERENCES billing.invoice (id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_item ADD CONSTRAINT fk_invoice_item_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE CASCADE;
ALTER TABLE billing.invoice_item ADD CONSTRAINT fk_invoice_item_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE billing.invoice_item ADD CONSTRAINT fk_invoice_item_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE CASCADE;
ALTER TABLE billing.profile_download_history ADD CONSTRAINT fk_profile_download_history_recruiter_user_id FOREIGN KEY (recruiter_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE billing.profile_download_history ADD CONSTRAINT fk_profile_download_history_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE billing.profile_download_history ADD CONSTRAINT fk_profile_download_history_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE billing.profile_download_history ADD CONSTRAINT fk_profile_download_history_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_saved_search ADD CONSTRAINT fk_candidate_saved_search_recruiter_user_id FOREIGN KEY (recruiter_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_saved_search ADD CONSTRAINT fk_candidate_saved_search_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_saved_search ADD CONSTRAINT fk_candidate_saved_search_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.job_alert_subscription ADD CONSTRAINT fk_job_alert_subscription_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE engagement.job_alert_subscription ADD CONSTRAINT fk_job_alert_subscription_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.job_alert_subscription ADD CONSTRAINT fk_job_alert_subscription_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.notification_delivery ADD CONSTRAINT fk_notification_delivery_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.notification_delivery ADD CONSTRAINT fk_notification_delivery_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.notification_delivery ADD CONSTRAINT fk_notification_delivery_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_recruiter_user_id FOREIGN KEY (recruiter_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition (id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_unlock_receipt_id FOREIGN KEY (unlock_receipt_id) REFERENCES billing.profile_download_history (id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.message_thread ADD CONSTRAINT fk_message_thread_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.thread_message ADD CONSTRAINT fk_thread_message_thread_id FOREIGN KEY (thread_id) REFERENCES engagement.message_thread (id) ON DELETE RESTRICT;
ALTER TABLE engagement.thread_message ADD CONSTRAINT fk_thread_message_sender_user_id FOREIGN KEY (sender_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.thread_message ADD CONSTRAINT fk_thread_message_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.thread_message ADD CONSTRAINT fk_thread_message_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_referral_link ADD CONSTRAINT fk_candidate_referral_link_referrer_user_id FOREIGN KEY (referrer_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_referral_link ADD CONSTRAINT fk_candidate_referral_link_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.candidate_referral_link ADD CONSTRAINT fk_candidate_referral_link_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.referral_attribution_event ADD CONSTRAINT fk_referral_attribution_event_referral_link_id FOREIGN KEY (referral_link_id) REFERENCES engagement.candidate_referral_link (id) ON DELETE RESTRICT;
ALTER TABLE engagement.referral_attribution_event ADD CONSTRAINT fk_referral_attribution_event_referred_user_id FOREIGN KEY (referred_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.referral_attribution_event ADD CONSTRAINT fk_referral_attribution_event_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.referral_attribution_event ADD CONSTRAINT fk_referral_attribution_event_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_placement_cohort ADD CONSTRAINT fk_campus_placement_cohort_tpo_user_id FOREIGN KEY (tpo_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_placement_cohort ADD CONSTRAINT fk_campus_placement_cohort_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_placement_cohort ADD CONSTRAINT fk_campus_placement_cohort_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_student_member ADD CONSTRAINT fk_campus_student_member_cohort_id FOREIGN KEY (cohort_id) REFERENCES engagement.campus_placement_cohort (id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_student_member ADD CONSTRAINT fk_campus_student_member_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_student_member ADD CONSTRAINT fk_campus_student_member_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE engagement.campus_student_member ADD CONSTRAINT fk_campus_student_member_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.dpdp_consent_record ADD CONSTRAINT fk_dpdp_consent_record_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.dpdp_consent_record ADD CONSTRAINT fk_dpdp_consent_record_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.dpdp_consent_record ADD CONSTRAINT fk_dpdp_consent_record_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.pii_encryption_key ADD CONSTRAINT fk_pii_encryption_key_user_id FOREIGN KEY (user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.pii_encryption_key ADD CONSTRAINT fk_pii_encryption_key_shredded_by_user_id FOREIGN KEY (shredded_by_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.pii_encryption_key ADD CONSTRAINT fk_pii_encryption_key_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.pii_encryption_key ADD CONSTRAINT fk_pii_encryption_key_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.system_audit_event ADD CONSTRAINT fk_system_audit_event_actor_user_id FOREIGN KEY (actor_user_id) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.data_retention_policy ADD CONSTRAINT fk_data_retention_policy_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE governance.data_retention_policy ADD CONSTRAINT fk_data_retention_policy_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_candidate ADD CONSTRAINT fk_dim_candidate_candidate_id FOREIGN KEY (candidate_id) REFERENCES candidate.candidate_profile (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_candidate ADD CONSTRAINT fk_dim_candidate_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_candidate ADD CONSTRAINT fk_dim_candidate_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_candidate ADD CONSTRAINT fk_dim_candidate_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_organisation ADD CONSTRAINT fk_dim_organisation_organisation_id FOREIGN KEY (organisation_id) REFERENCES organisation.organisation (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_organisation ADD CONSTRAINT fk_dim_organisation_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_organisation ADD CONSTRAINT fk_dim_organisation_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_job_requisition ADD CONSTRAINT fk_dim_job_requisition_requisition_id FOREIGN KEY (requisition_id) REFERENCES recruitment.job_requisition (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_job_requisition ADD CONSTRAINT fk_dim_job_requisition_salary_currency_code FOREIGN KEY (salary_currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_job_requisition ADD CONSTRAINT fk_dim_job_requisition_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_job_requisition ADD CONSTRAINT fk_dim_job_requisition_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_pipeline_stage ADD CONSTRAINT fk_dim_pipeline_stage_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.dim_pipeline_stage ADD CONSTRAINT fk_dim_pipeline_stage_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date (date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_candidate_key FOREIGN KEY (candidate_key) REFERENCES analytics.dim_candidate (candidate_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation (organisation_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_requisition_key FOREIGN KEY (requisition_key) REFERENCES analytics.dim_job_requisition (requisition_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_from_stage_key FOREIGN KEY (from_stage_key) REFERENCES analytics.dim_pipeline_stage (stage_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_to_stage_key FOREIGN KEY (to_stage_key) REFERENCES analytics.dim_pipeline_stage (stage_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_application_event ADD CONSTRAINT fk_fact_application_event_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_profile_download ADD CONSTRAINT fk_fact_profile_download_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date (date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_profile_download ADD CONSTRAINT fk_fact_profile_download_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation (organisation_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_profile_download ADD CONSTRAINT fk_fact_profile_download_candidate_key FOREIGN KEY (candidate_key) REFERENCES analytics.dim_candidate (candidate_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_profile_download ADD CONSTRAINT fk_fact_profile_download_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_gig_contract ADD CONSTRAINT fk_fact_gig_contract_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date (date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_gig_contract ADD CONSTRAINT fk_fact_gig_contract_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation (organisation_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_gig_contract ADD CONSTRAINT fk_fact_gig_contract_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_wallet_transaction ADD CONSTRAINT fk_fact_wallet_transaction_date_key FOREIGN KEY (date_key) REFERENCES analytics.dim_date (date_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_wallet_transaction ADD CONSTRAINT fk_fact_wallet_transaction_organisation_key FOREIGN KEY (organisation_key) REFERENCES analytics.dim_organisation (organisation_key) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_wallet_transaction ADD CONSTRAINT fk_fact_wallet_transaction_currency_code FOREIGN KEY (currency_code) REFERENCES master_data.currency (currency_code) ON DELETE RESTRICT;
ALTER TABLE analytics.fact_wallet_transaction ADD CONSTRAINT fk_fact_wallet_transaction_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.enum_lookup ADD CONSTRAINT fk_enum_lookup_language_code FOREIGN KEY (language_code) REFERENCES master_data.language (language_code) ON DELETE RESTRICT;
ALTER TABLE master_data.enum_lookup ADD CONSTRAINT fk_enum_lookup_created_by FOREIGN KEY (created_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;
ALTER TABLE master_data.enum_lookup ADD CONSTRAINT fk_enum_lookup_updated_by FOREIGN KEY (updated_by) REFERENCES identity.user_account (id) ON DELETE RESTRICT;

-- -------------------------------------------------------------
-- PERFORMANCE INDEXES (Trigram, Range & Covering)
-- -------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_candidate_profile_user ON candidate.candidate_profile (user_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_city ON candidate.candidate_profile (current_city_id);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_exp ON candidate.candidate_profile (total_experience_months);
CREATE INDEX IF NOT EXISTS idx_candidate_profile_searchable ON candidate.candidate_profile (is_profile_searchable) WHERE is_profile_searchable = TRUE;
CREATE INDEX IF NOT EXISTS idx_candidate_skill_lookup ON candidate.candidate_skill (candidate_id, skill_id);

-- Exact column names in candidate_block_list: blocked_organisation_id, blocked_recruiter_user_id
CREATE INDEX IF NOT EXISTS idx_candidate_block_org ON candidate.candidate_block_list (candidate_id, blocked_organisation_id);
CREATE INDEX IF NOT EXISTS idx_candidate_block_recruiter ON candidate.candidate_block_list (candidate_id, blocked_recruiter_user_id);

-- Exact column names in job_requisition: publish_status, open_to_consultants
CREATE INDEX IF NOT EXISTS idx_job_requisition_org ON recruitment.job_requisition (organisation_id);
CREATE INDEX IF NOT EXISTS idx_job_requisition_publish_status ON recruitment.job_requisition (publish_status);
CREATE INDEX IF NOT EXISTS idx_job_requisition_consultant ON recruitment.job_requisition (open_to_consultants) WHERE open_to_consultants = TRUE;

-- Exact column name in job_application: requisition_id
CREATE INDEX IF NOT EXISTS idx_job_application_req_cand ON application.job_application (requisition_id, candidate_id);
CREATE INDEX IF NOT EXISTS idx_job_application_status ON application.job_application (application_status);

CREATE INDEX IF NOT EXISTS idx_gig_request_status ON gig.gig_request (request_status);
CREATE INDEX IF NOT EXISTS idx_gig_contract_parties ON gig.gig_contract (client_account_id, gig_worker_id);

CREATE INDEX IF NOT EXISTS idx_wallet_ledger_account ON billing.wallet_ledger (wallet_account_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_event_actor ON governance.system_audit_event (actor_user_id, event_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_notification_user ON engagement.notification_delivery (user_id, created_at DESC);

-- -------------------------------------------------------------
-- ROW-LEVEL SECURITY (RLS) POLICIES (Section 3 Rules You Must Honour)
-- -------------------------------------------------------------
ALTER TABLE candidate.candidate_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE candidate.candidate_block_list ENABLE ROW LEVEL SECURITY;
ALTER TABLE recruitment.job_requisition ENABLE ROW LEVEL SECURITY;
ALTER TABLE application.job_application ENABLE ROW LEVEL SECURITY;
ALTER TABLE identity.user_credential ENABLE ROW LEVEL SECURITY;
ALTER TABLE billing.wallet_account ENABLE ROW LEVEL SECURITY;

-- Policy 1: Candidate can view and update their own profile
CREATE POLICY p_candidate_own_profile ON candidate.candidate_profile
    FOR ALL
    USING (
        user_id = NULLIF(current_setting('app.current_user_id', true), '')::UUID
        OR current_setting('app.current_role', true) IN ('SUPER_ADMIN', 'ADMIN')
    );

-- Policy 2: Candidate search with Anti-Join Privacy Shield (using exact column blocked_organisation_id)
CREATE POLICY p_candidate_recruiter_search ON candidate.candidate_profile
    FOR SELECT
    USING (
        is_profile_searchable = TRUE
        AND deleted_at IS NULL
        AND NOT EXISTS (
            SELECT 1 
            FROM candidate.candidate_block_list bl
            WHERE bl.candidate_id = candidate.candidate_profile.id
              AND bl.blocked_organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID
        )
    );

-- Policy 3: Candidate can view and manage only their own block entries
CREATE POLICY p_candidate_own_blocks ON candidate.candidate_block_list
    FOR ALL
    USING (
        candidate_id IN (
            SELECT cp.id 
            FROM candidate.candidate_profile cp 
            WHERE cp.user_id = NULLIF(current_setting('app.current_user_id', true), '')::UUID
        )
        OR current_setting('app.current_role', true) IN ('SUPER_ADMIN', 'ADMIN')
    );

-- Policy 4: Recruiter may ONLY see job requisitions assigned to their own company
CREATE POLICY p_recruiter_own_company_requisitions ON recruitment.job_requisition
    FOR ALL
    USING (
        organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID
        OR current_setting('app.current_role', true) IN ('SUPER_ADMIN', 'ADMIN')
    );

-- Policy 5: Sourcing Consultant may ONLY view requisitions open to consultants (open_to_consultants & publish_status)
CREATE POLICY p_consultant_open_requisitions ON recruitment.job_requisition
    FOR SELECT
    USING (
        current_setting('app.current_role', true) = 'CONSULTANT'
        AND open_to_consultants = TRUE
        AND publish_status = 'PUBLISHED'
        AND deleted_at IS NULL
    );

-- Policy 6: Candidate can view/withdraw only their own applications
CREATE POLICY p_candidate_own_applications ON application.job_application
    FOR ALL
    USING (
        candidate_id IN (
            SELECT cp.id 
            FROM candidate.candidate_profile cp 
            WHERE cp.user_id = NULLIF(current_setting('app.current_user_id', true), '')::UUID
        )
        OR current_setting('app.current_role', true) IN ('SUPER_ADMIN', 'ADMIN')
    );

-- Policy 7: Recruiter can view applications only for their own company requisitions
CREATE POLICY p_recruiter_own_applications ON application.job_application
    FOR SELECT
    USING (
        requisition_id IN (
            SELECT jr.id 
            FROM recruitment.job_requisition jr 
            WHERE jr.organisation_id = NULLIF(current_setting('app.current_org_id', true), '')::UUID
        )
        OR current_setting('app.current_role', true) IN ('SUPER_ADMIN', 'ADMIN')
    );

-- Policy 8: User can only access their own credentials
CREATE POLICY p_user_own_credentials ON identity.user_credential
    FOR ALL
    USING (
        user_id = NULLIF(current_setting('app.current_user_id', true), '')::UUID
        OR current_setting('app.current_role', true) = 'SUPER_ADMIN'
    );

-- Policy 9: Organisation wallet access strictly isolated to owning account (using exact column account_id)
CREATE POLICY p_organisation_wallet_isolation ON billing.wallet_account
    FOR ALL
    USING (
        account_id = NULLIF(current_setting('app.current_account_id', true), '')::UUID
        OR current_setting('app.current_role', true) IN ('SUPER_ADMIN', 'FINANCE_ADMIN')
    );
