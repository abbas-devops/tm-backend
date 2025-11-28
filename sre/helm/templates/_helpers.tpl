{{/*
Template name prefix based on chart name
*/}}
{{- define "common.prefix" -}}
{{- .Chart.Name -}}
{{- end }}

{{/*
AWS configuration with safe fallback to configured defaults
*/}}
{{- define "common.aws.accountId" -}}
{{- if and .Values.aws .Values.aws.accountId -}}
{{- .Values.aws.accountId -}}
{{- end -}}
{{- end }}

{{- define "common.aws.region" -}}
{{- if and .Values.aws .Values.aws.region -}}
{{- .Values.aws.region -}}
{{- end -}}
{{- end }}

{{- define "common.aws.eksName" -}}
{{- if and .Values.aws .Values.aws.eksName -}}
{{- .Values.aws.eksName -}}
{{- end -}}
{{- end }}

{{- define "common.aws.albCertificateArn" -}}
{{- if and .Values.aws .Values.aws.albCertificateArn -}}
{{- .Values.aws.albCertificateArn -}}
{{- end -}}
{{- end }}

{{- define "common.aws.oidcProvider" -}}
{{- if and .Values.aws .Values.aws.oidcProvider -}}
{{- .Values.aws.oidcProvider -}}
{{- end -}}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "common.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "common.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "common.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "common.labels" -}}
app: {{ .Values.appName }}
helm.sh/chart: {{ include "common.chart" . }}
{{ include "common.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
release: {{ .Release.Name }}
heritage: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "common.selectorLabels" -}}
app: {{ .Values.appName }}
app.kubernetes.io/name: {{ include "common.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
release: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "common.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default .Values.appName .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Generate AWS Secrets Manager objects configuration
*/}}
{{- define "common.secretsObjects" -}}
{{- range .Values.envVars }}
        - objectName: {{ . }}
          key: {{ . }}
{{- end }}
{{- end }}

{{/*
Generate JMESPath configuration for AWS Secrets
*/}}
{{- define "common.jmesPath" -}}
{{- range .Values.envVars }}
            - path: {{ . }}
              objectAlias: {{ . }}
{{- end }}
{{- end }}

{{/*
Generate environment variables for deployment
*/}}
{{- define "common.envVars" -}}
{{- range .Values.envVars }}
            - name: {{ . }}
              valueFrom:
                secretKeyRef:
                  name: app-config
                  key: {{ . }}
{{- end }}
{{- end }}

{{/*
Generate probe configuration
*/}}
{{- define "common.probes" -}}
{{- if .Values.probes.liveness }}
livenessProbe:
  {{- toYaml .Values.probes.liveness | nindent 2 }}
{{- end }}
{{- if .Values.probes.readiness }}
readinessProbe:
  {{- toYaml .Values.probes.readiness | nindent 2 }}
{{- end }}
{{- if .Values.probes.startup }}
startupProbe:
  {{- toYaml .Values.probes.startup | nindent 2 }}
{{- end }}
{{- end }}

{{/*
Generate full ECR image URL
*/}}
{{- define "common.image" -}}
{{- printf "%s.dkr.ecr.%s.amazonaws.com/%s:%s" (include "common.aws.accountId" .) (include "common.aws.region" .) .Values.image.repository .Values.image.tag -}}
{{- end }}