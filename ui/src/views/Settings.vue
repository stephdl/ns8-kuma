<!--
  Copyright (C) 2022 Nethesis S.r.l.
  SPDX-License-Identifier: GPL-3.0-or-later
-->
<template>
  <cv-grid fullWidth>
    <cv-row>
      <cv-column class="page-title">
        <h2>{{ $t("settings.title") }}</h2>
      </cv-column>
    </cv-row>
    <cv-row v-if="error.getConfiguration">
      <cv-column>
        <NsInlineNotification
          kind="error"
          :title="$t('action.get-configuration')"
          :description="error.getConfiguration"
          :showCloseButton="false"
        />
      </cv-column>
    </cv-row>
    <cv-row>
      <cv-column>
        <cv-tile light>
          <cv-form @submit.prevent="configureModule">
            <cv-text-input
              :label="$t('settings.kuma_fqdn')"
              placeholder="kuma.example.org"
              v-model.trim="host"
              class="mg-bottom"
              :invalid-message="$t(error.host)"
              :disabled="loading.getConfiguration || loading.configureModule"
              ref="host"
            >
            </cv-text-input>
            <NsToggle
              value="letsEncrypt"
              :label="core.$t('apps_lets_encrypt.request_https_certificate')"
              v-model="isLetsEncryptEnabled"
              :disabled="stillLoading"
              class="mg-bottom"
            >
              <template #tooltip>
                <div class="mg-bottom-sm">
                  {{ core.$t("apps_lets_encrypt.lets_encrypt_tips") }}
                </div>
                <div class="mg-bottom-sm">
                  <cv-link @click="goToCertificates">
                    {{ core.$t("apps_lets_encrypt.go_to_tls_certificates") }}
                  </cv-link>
                </div>
              </template>
              <template slot="text-left">{{
                $t("settings.disabled")
              }}</template>
              <template slot="text-right">{{
                $t("settings.enabled")
              }}</template>
            </NsToggle>
            <cv-row
              v-if="isLetsEncryptCurrentlyEnabled && !isLetsEncryptEnabled"
            >
              <cv-column>
                <NsInlineNotification
                  kind="warning"
                  :title="
                    core.$t('apps_lets_encrypt.lets_encrypt_disabled_warning')
                  "
                  :description="
                    core.$t(
                      'apps_lets_encrypt.lets_encrypt_disabled_warning_description',
                      {
                        node: this.status.node_ui_name
                          ? this.status.node_ui_name
                          : this.status.node,
                      }
                    )
                  "
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <h4 class="mg-bottom-sm">{{ $t("settings.admin_title") }}</h4>
            <template v-if="isAdminConfigured">
              <NsInlineNotification
                kind="info"
                :title="$t('settings.admin_configured')"
                :description="$t('settings.admin_configured_description')"
                :actionLabel="host ? $t('status.open_webapp') : ''"
                @action="goToWebapp"
                :showCloseButton="false"
              />
              <cv-text-input
                :label="$t('settings.admin_username')"
                :value="adminUsername"
                class="mg-bottom"
                disabled
              />
            </template>
            <template v-else-if="!loading.getConfiguration">
              <p class="mg-bottom">{{ $t("settings.admin_description") }}</p>
              <cv-text-input
                :label="$t('settings.admin_username')"
                v-model.trim="adminUsername"
                class="mg-bottom"
                :invalid-message="$t(error.admin_username)"
                :disabled="stillLoading"
                ref="admin_username"
              >
              </cv-text-input>
              <NsPasswordInput
                :newPasswordLabel="$t('settings.admin_password')"
                :confirmPasswordLabel="$t('settings.admin_password_confirm')"
                v-model="adminPassword"
                @passwordValidation="onAdminPasswordValidation"
                :newPaswordHelperText="$t('settings.admin_password_helper')"
                :newPasswordInvalidMessage="$t(error.admin_password)"
                :confirmPasswordInvalidMessage="
                  $t(error.admin_password_confirm)
                "
                :passwordHideLabel="core.$t('password.hide_password')"
                :passwordShowLabel="core.$t('password.show_password')"
                :lengthLabel="core.$t('password.long_enough')"
                :lowercaseLabel="core.$t('password.lowercase_letter')"
                :uppercaseLabel="core.$t('password.uppercase_letter')"
                :numberLabel="core.$t('password.number')"
                :symbolLabel="core.$t('password.symbol')"
                :equalLabel="core.$t('password.equal')"
                :focus="focusPasswordField"
                :minLength="8"
                :disabled="stillLoading"
                class="mg-bottom"
              />
            </template>
            <!-- advanced options -->
            <cv-accordion ref="accordion" class="maxwidth mg-bottom">
              <cv-accordion-item :open="isAdvancedOpen">
                <template slot="title">{{ $t("settings.advanced") }}</template>
                <template slot="content">
                  <NsToggle
                    value="smtpEnabled"
                    :label="$t('settings.smtp_enabled')"
                    v-model="isSmtpEnabled"
                    :disabled="
                      stillLoading || (!isSmarthostAvailable && !isSmtpEnabled)
                    "
                    class="mg-bottom"
                  >
                    <template #tooltip>
                      <div class="mg-bottom-sm">
                        {{ $t("settings.smtp_enabled_tooltip") }}
                      </div>
                      <div class="mg-bottom-sm">
                        <cv-link @click="goToEmailNotifications">
                          {{ $t("settings.go_to_email_notifications") }}
                        </cv-link>
                      </div>
                    </template>
                    <template slot="text-left">{{
                      $t("settings.disabled")
                    }}</template>
                    <template slot="text-right">{{
                      $t("settings.enabled")
                    }}</template>
                  </NsToggle>
                  <NsInlineNotification
                    v-if="!loading.getConfiguration && !isSmarthostAvailable"
                    kind="info"
                    :title="$t('settings.smarthost_not_configured')"
                    :description="
                      $t('settings.smarthost_not_configured_description')
                    "
                    :actionLabel="$t('settings.go_to_email_notifications')"
                    @action="goToEmailNotifications"
                    :showCloseButton="false"
                  />
                  <cv-text-area
                    v-if="isSmtpEnabled"
                    :label="$t('settings.notification_emails')"
                    :helper-text="$t('settings.notification_emails_helper')"
                    placeholder="admin@example.org"
                    v-model="notificationEmails"
                    class="mg-bottom maxwidth"
                    :invalid-message="error.notification_emails"
                    :disabled="stillLoading"
                    ref="notification_emails"
                  />
                </template>
              </cv-accordion-item>
            </cv-accordion>
            <cv-row v-if="error.configureModule">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.configure-module')"
                  :description="error.configureModule"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <cv-row v-if="error.getStatus">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="$t('action.get-status')"
                  :description="error.getStatus"
                  :showCloseButton="false"
                />
              </cv-column>
            </cv-row>
            <cv-row v-if="validationErrorDetails.length">
              <cv-column>
                <NsInlineNotification
                  kind="error"
                  :title="
                    core.$t('apps_lets_encrypt.cannot_obtain_certificate')
                  "
                  :showCloseButton="false"
                >
                  <template #description>
                    <div class="flex flex-col gap-2">
                      <div
                        v-for="(detail, index) in validationErrorDetails"
                        :key="index"
                      >
                        {{ detail }}
                      </div>
                    </div>
                  </template>
                </NsInlineNotification>
              </cv-column>
            </cv-row>
            <NsButton
              kind="primary"
              :icon="Save20"
              :loading="loading.configureModule"
              :disabled="loading.getConfiguration || loading.configureModule"
              >{{ $t("settings.save") }}</NsButton
            >
          </cv-form>
        </cv-tile>
      </cv-column>
    </cv-row>
  </cv-grid>
</template>

<script>
import to from "await-to-js";
import { mapState } from "vuex";
import {
  QueryParamService,
  UtilService,
  TaskService,
  IconService,
  PageTitleService,
} from "@nethserver/ns8-ui-lib";

export default {
  name: "Settings",
  mixins: [
    TaskService,
    IconService,
    UtilService,
    QueryParamService,
    PageTitleService,
  ],
  pageTitle() {
    return this.$t("settings.title") + " - " + this.appName;
  },
  data() {
    return {
      q: {
        page: "settings",
      },
      status: {},
      validationErrorDetails: [],
      urlCheckInterval: null,
      host: "",
      isLetsEncryptEnabled: false,
      isLetsEncryptCurrentlyEnabled: false,
      isAdminConfigured: true,
      adminUsername: "",
      adminPassword: "",
      adminPasswordValidation: null,
      focusPasswordField: { element: "" },
      isSmarthostAvailable: false,
      isSmtpEnabled: false,
      isAdvancedOpen: false,
      notificationEmails: "",
      loading: {
        getConfiguration: false,
        configureModule: false,
        getStatus: false,
      },
      error: {
        getConfiguration: "",
        configureModule: "",
        host: "",
        lets_encrypt: "",
        admin_username: "",
        admin_password: "",
        admin_password_confirm: "",
        notification_emails: "",
        getStatus: false,
      },
    };
  },
  computed: {
    ...mapState(["instanceName", "core", "appName"]),
    stillLoading() {
      return (
        this.loading.getConfiguration ||
        this.loading.configureModule ||
        this.loading.getStatus
      );
    },
  },
  created() {
    this.getConfiguration();
    this.getStatus();
  },
  beforeRouteEnter(to, from, next) {
    next((vm) => {
      vm.watchQueryData(vm);
      vm.urlCheckInterval = vm.initUrlBindingForApp(vm, vm.q.page);
    });
  },
  beforeRouteLeave(to, from, next) {
    clearInterval(this.urlCheckInterval);
    next();
  },
  methods: {
    goToCertificates() {
      this.core.$router.push("/settings/tls-certificates");
    },
    goToWebapp() {
      window.open(`https://${this.host}`, "_blank");
    },
    goToEmailNotifications() {
      this.core.$router.push("/settings/smarthost");
    },
    emailList() {
      // One address per line, commas and spaces accepted too
      return [
        ...new Set(
          this.notificationEmails.split(/[\s,;]+/).filter((email) => email)
        ),
      ];
    },
    onAdminPasswordValidation(validation) {
      this.adminPasswordValidation = validation;
    },
    async getStatus() {
      this.loading.getStatus = true;
      this.error.getStatus = "";
      const taskAction = "get-status";
      const eventId = this.getUuid();
      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getStatusAborted
      );
      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getStatusCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];
      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getStatus = this.getErrorMessage(err);
        this.loading.getStatus = false;
        return;
      }
    },
    getStatusAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getStatus = this.$t("error.generic_error");
      this.loading.getStatus = false;
    },
    getStatusCompleted(taskContext, taskResult) {
      this.status = taskResult.output;
      this.loading.getStatus = false;
    },
    async getConfiguration() {
      this.loading.getConfiguration = true;
      this.error.getConfiguration = "";
      const taskAction = "get-configuration";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.getConfigurationAborted
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.getConfigurationCompleted
      );

      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          extra: {
            title: this.$t("action." + taskAction),
            isNotificationHidden: true,
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.getConfiguration = this.getErrorMessage(err);
        this.loading.getConfiguration = false;
        return;
      }
    },
    getConfigurationAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.getConfiguration = this.$t("error.generic_error");
      this.loading.getConfiguration = false;
    },
    getConfigurationCompleted(taskContext, taskResult) {
      const config = taskResult.output;
      this.host = config.host;
      this.isLetsEncryptEnabled = config.lets_encrypt;
      this.isLetsEncryptCurrentlyEnabled = config.lets_encrypt;
      this.isAdminConfigured = config.admin_username !== "";
      this.isSmarthostAvailable = config.smarthost_available;
      this.isSmtpEnabled = config.smtp_enabled;
      this.notificationEmails = config.notification_emails.join("\n");
      this.adminUsername = config.admin_username;
      this.adminPassword = "";

      this.loading.getConfiguration = false;
      this.focusElement("host");
    },
    validateConfigureModule() {
      this.clearErrors(this);
      this.validationErrorDetails = [];

      let isValidationOk = true;
      if (!this.host) {
        this.error.host = "common.required";

        if (isValidationOk) {
          this.focusElement("host");
        }
        isValidationOk = false;
      }

      if (!this.isAdminConfigured) {
        if (!this.adminUsername) {
          this.error.admin_username = "common.required";
          if (isValidationOk) {
            this.focusElement("admin_username");
          }
          isValidationOk = false;
        }
        const v = this.adminPasswordValidation;
        if (
          !v ||
          !v.isLengthOk ||
          !v.isLowercaseOk ||
          !v.isUppercaseOk ||
          !v.isNumberOk ||
          !v.isSymbolOk
        ) {
          this.error.admin_password = "settings.admin_password_too_weak";
          if (isValidationOk) {
            this.focusPasswordField = { element: "newPassword" };
          }
          isValidationOk = false;
        } else if (!v.isEqualOk) {
          this.error.admin_password_confirm =
            "settings.admin_password_mismatch";
          if (isValidationOk) {
            this.focusPasswordField = { element: "confirmPassword" };
          }
          isValidationOk = false;
        }
      }

      if (this.isSmtpEnabled) {
        const emails = this.emailList();
        const invalid = emails.find(
          (email) => !/^[^\s@]+@[^\s@]+$/.test(email)
        );
        if (!emails.length || invalid) {
          this.error.notification_emails = emails.length
            ? this.$t("settings.invalid_email", { email: invalid })
            : this.$t("common.required");
          // The field lives in the collapsed advanced section
          this.isAdvancedOpen = true;
          if (isValidationOk) {
            this.$nextTick(() => this.focusElement("notification_emails"));
          }
          isValidationOk = false;
        }
      }
      return isValidationOk;
    },
    configureModuleValidationFailed(validationErrors) {
      this.loading.configureModule = false;
      let focusAlreadySet = false;
      for (const validationError of validationErrors) {
        const param = validationError.parameter;
        if (validationError.details) {
          // show inline error notification with details
          this.validationErrorDetails = validationError.details
            .split("\n")
            .filter((detail) => detail.trim() !== "");
        } else {
          // set i18n error message
          this.error[param] = this.$t("settings." + validationError.error);
          if (!focusAlreadySet) {
            this.focusElement(param);
            focusAlreadySet = true;
          }
        }
      }
    },
    async configureModule() {
      const isValidationOk = this.validateConfigureModule();
      if (!isValidationOk) {
        return;
      }

      this.loading.configureModule = true;
      const taskAction = "configure-module";
      const eventId = this.getUuid();

      // register to task error
      this.core.$root.$once(
        `${taskAction}-aborted-${eventId}`,
        this.configureModuleAborted
      );

      // register to task validation
      this.core.$root.$once(
        `${taskAction}-validation-failed-${eventId}`,
        this.configureModuleValidationFailed
      );

      // register to task completion
      this.core.$root.$once(
        `${taskAction}-completed-${eventId}`,
        this.configureModuleCompleted
      );
      const res = await to(
        this.createModuleTaskForApp(this.instanceName, {
          action: taskAction,
          data: {
            host: this.host,
            lets_encrypt: this.isLetsEncryptEnabled,
            smtp_enabled: this.isSmtpEnabled,
            notification_emails: this.isSmtpEnabled ? this.emailList() : [],
            ...(!this.isAdminConfigured && this.adminPassword
              ? {
                  admin_username: this.adminUsername,
                  admin_password: this.adminPassword,
                }
              : {}),
          },
          extra: {
            title: this.$t("settings.instance_configuration", {
              instance: this.instanceName,
            }),
            description: this.$t("settings.configuring"),
            eventId,
          },
        })
      );
      const err = res[0];

      if (err) {
        console.error(`error creating task ${taskAction}`, err);
        this.error.configureModule = this.getErrorMessage(err);
        this.loading.configureModule = false;
        return;
      }
    },
    configureModuleAborted(taskResult, taskContext) {
      console.error(`${taskContext.action} aborted`, taskResult);
      this.error.configureModule = this.$t("error.generic_error");
      this.loading.configureModule = false;
    },
    configureModuleCompleted() {
      this.loading.configureModule = false;

      // reload configuration
      this.getConfiguration();
    },
  },
};
</script>

<style scoped lang="scss">
@import "../styles/carbon-utils";
.mg-bottom {
  margin-bottom: $spacing-06;
}

.mg-bottom-sm {
  margin-bottom: $spacing-03;
}

.maxwidth {
  max-width: 38rem;
}
</style>
