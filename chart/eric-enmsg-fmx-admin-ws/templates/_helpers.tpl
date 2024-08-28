{{/*
Generate WPServ Instances Dynamically
*/}}
{{- define "{{.Chart.Name}}.podsname" -}}
    {{- $release := .Release.Namespace -}}
    {{- "wpserv" }}.{{ $release }}.svc.cluster.local
{{- end -}}

