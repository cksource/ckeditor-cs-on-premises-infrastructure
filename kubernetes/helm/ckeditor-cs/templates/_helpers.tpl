{{/*
Expand the name of the chart.
*/}}
{{- define "ckeditor-cs.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "ckeditor-cs.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create unified labels for ckeditor-cs
*/}}
{{- define "ckeditor-cs.common.matchLabels" -}}
app.kubernetes.io/name: {{ template "ckeditor-cs.name" }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "ckeditor-cs.common.metaLabels" -}}
helm.sh/chart: {{ template "ckeditor-cs.chart" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "ckeditor-cs.server.labels" -}}
{{ include "ckeditor-cs.server.matchLabels" }}
{{ include "ckeditor-cs.common.metaLabels" }}
{{- end }}

{{- define "ckeditor-cs.server.matchLabels" -}}
app.kubernetes.io/component: {{ .Values.server.name | quote }}
{{ include "ckeditor-cs.common.matchLabels" . }}
{{- end }}

{{- define "ckeditor-cs.worker.labels" -}}
{{ include "ckeditor-cs.worker.matchLabels" }}
{{ include "ckeditor-cs.common.metaLabels"}}
{{- end }}

{{- define "ckeditor-cs.worker.matchLabels" -}}
app.kubernetes.io/component: {{ .Values.worker.name | quote }}
{{ include "ckeditor-cs.common.matchLabels" }}
{{- end }}

{{/*
Create a default fully qualified server name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "ckeditor-cs.server.fullname" -}}
{{- if .Values.server.fullnameOverride -}}
{{- .Values.server.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.server.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.server.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified worker name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "ckeditor-cs.worker.fullname" -}}
{{- if .Values.worker.fullnameOverride -}}
{{- .Values.worker.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "%s-%s" .Release.Name .Values.worker.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-%s" .Release.Name $name .Values.worker.name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Create the name of the service account to use for server
*/}}
{{- define "ckeditor-cs.server.serviceAccountName" -}}
{{- if .Values.server.serviceAccount.create }}
{{- default (include "ckeditor-cs.server.fullname" .) .Values.server.serviceAccount.name }}
{{- else }}
{{- default "ckeditor-cs" .Values.server.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use for worker
*/}}
{{- define "ckeditor-cs.worker.serviceAccountName" -}}
{{- if .Values.worker.serviceAccount.create }}
{{- default (include "ckeditor-cs.worker.fullname" .) .Values.worker.serviceAccount.name }}
{{- else }}
{{- default "ckeditor-cs" .Values.worker.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use
*/}}
{{- define "ckeditor-cs.server.secretName" -}}
{{- if .Values.server.secret.create }}
{{- default (include "ckeditor-cs.server.fullname" .) .Values.server.secret.name }}
{{- else }}
{{- default "ckeditor-cs" .Values.server.secret.name }}
{{- end }}
{{- end }}

{{/*
Create the name of the secret to use for worker
*/}}
{{- define "ckeditor-cs.worker.secretName" -}}
{{- if .Values.worker.secret.create }}
{{- default (include "ckeditor-cs.worker.fullname" .) .Values.worker.secret.name }}
{{- else }}
{{- default "ckeditor-cs-worker" .Values.worker.secret.name }}
{{- end }}
{{- end }}
