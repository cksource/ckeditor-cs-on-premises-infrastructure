{{/*
Expand the name of the chart.
*/}}
{{- define "ckbox.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ckbox.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create unified labels for ckbox
*/}}
{{- define "ckbox.common.matchLabels" -}}
app.kubernetes.io/name: {{ template "ckbox.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "ckbox.common.metaLabels" -}}
helm.sh/chart: {{ template "ckbox.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "ckbox.labels" -}}
{{ include "ckbox.matchLabels" . }}
{{ include "ckbox.common.metaLabels" . }}
{{- end }}

{{- define "ckbox.matchLabels" -}}
{{ include "ckbox.common.matchLabels" . }}
{{- end }}


{{/*
Create a default fully qualified server name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "ckbox.fullname" -}}
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
Create the name of the service account to use for server
*/}}
{{- define "ckbox.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "ckbox.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "ckbox" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "ckbox.secretName" -}}
{{- if .Values.secret.create }}
{{- default (include "ckbox.fullname" .) .Values.secret.name }}
{{- else }}
{{- default "ckbox" .Values.secret.name }}
{{- end }}
{{- end }}
