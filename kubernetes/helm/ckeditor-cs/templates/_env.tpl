{{/*
Create environment variables from existing secrets and additional env vars
*/}}
{{- define "ckeditor-cs.env" -}}
{{- $component := .component -}}
{{- $values := .values -}}
{{- $env := list -}}

{{/* Add environment variables from existing secrets */}}
{{- range $values.env.existingSecrets -}}
{{- $env = append $env (dict "name" .envVar "valueFrom" (dict "secretKeyRef" (dict "name" .name "key" .key))) -}}
{{- end -}}

{{/* Add additional environment variables */}}
{{- range $values.env.additional -}}
{{- $env = append $env (dict "name" .name "value" .value) -}}
{{- end -}}

{{/* Add environment variables from component secret */}}
{{- if $values.secret.data -}}
{{- range $key, $value := $values.secret.data -}}
{{- if $value -}}
{{- $env = append $env (dict "name" $key "valueFrom" (dict "secretKeyRef" (dict "name" $values.secret.name "key" $key))) -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- toYaml $env -}}
{{- end -}} 