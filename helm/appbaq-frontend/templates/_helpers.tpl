{{- define "appbaq-frontend.name" -}}
{{- .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "appbaq-frontend.fullname" -}}
{{- printf "appbaq-frontend" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "appbaq-frontend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "appbaq-frontend.selectorLabels" -}}
app.kubernetes.io/name: {{ include "appbaq-frontend.name" . }}
app.kubernetes.io/component: frontend
{{- end -}}

{{- define "appbaq-frontend.commonLabels" -}}
helm.sh/chart: {{ include "appbaq-frontend.chart" . }}
{{ include "appbaq-frontend.selectorLabels" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/part-of: {{ index .Values.global.labels "app.kubernetes.io/part-of" | quote }}
environment: {{ .Values.global.labels.environment | quote }}
owner: {{ .Values.global.labels.owner | quote }}
{{- end -}}

{{- define "appbaq-frontend.labels" -}}
{{ include "appbaq-frontend.commonLabels" . }}
{{- end -}}
