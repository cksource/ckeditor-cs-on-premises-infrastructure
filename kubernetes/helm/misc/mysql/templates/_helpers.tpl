{{- define "mysql.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "mysql.fullname" -}}
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

{{- define "mysql.labels" -}}
app.kubernetes.io/name: {{ include "mysql.name" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{ include "mysql.selectorLabels" . }}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels | nindent 0 }}
{{- end }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "mysql.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mysql.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
