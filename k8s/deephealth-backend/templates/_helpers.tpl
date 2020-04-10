{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "deephealth-backend.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "deephealth-backend.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "deephealth-backend.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "deephealth-backend.djangoSecretKey" -}}
{{- randAlphaNum 50 | b64enc -}}
{{- end -}}


{{/*
Return Django admin password
*/}}
{{- define "deephealth-backend.admin.password" -}}
{{- if .Values.backend.admin.password -}}
    {{- .Values.backend.admin.password -}}
{{- else -}}
    {{- randAlphaNum 10 -}}
{{- end -}}
{{- end -}}

{{/*
Return Django static_files url
*/}}
{{- define "deephealth-backend.static_files.url" -}}
/static/
{{- end -}}

{{/*
Return Django static_files path
*/}}
{{- define "deephealth-backend.static_files.path" -}}
{{- $url := .Values.nginx.serverDataVolumePath | trimSuffix "/" -}}
{{- printf "%s/" $url -}}
{{- end -}}

{{/*
Define admin credentials via environment variables.
*/}}
{{- define "deephealth-backend.adminCredentials" -}}
- name: ADMIN_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "deephealth-backend.fullname" . }}-secrets
      key: adminUsername
- name: ADMIN_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "deephealth-backend.fullname" . }}-secrets
      key: adminPassword
{{- if .Values.backend.admin.email -}}
- name: ADMIN_EMAIL
  valueFrom:
    secretKeyRef:
      name: {{ include "deephealth-backend.fullname" . }}-secrets
      key: adminEmail
{{- end -}}
{{- end -}}


{{/*
Define environment variables in connection between some pods.
*/}}
{{- define "deephealth-backend.django.secretName" -}}
{{- printf "deephealth-backend-django-secrets" -}}
{{- end -}}

{{/*
Define environment variables in connection between some pods.
*/}}
{{- define "deephealth-backend.postgresql.secretName" -}}
{{- if .Values.postgresql.existingSecret -}}
{{- printf "%s" .Values.postgresql.existingSecret -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Define environment variables in connection between some pods.
*/}}
{{- define "deephealth-backend.rabbitmq.secretName" -}}
{{- if .Values.rabbitmq.rabbitmq.existingPasswordSecret -}}
{{- printf "%s" .Values.rabbitmq.rabbitmq.existingPasswordSecret -}}
{{- else -}}
{{- printf "%s-rabbitmq" .Release.Name -}}
{{- end -}}
{{- end -}}

{{/*
Define environment variables in connection between some pods.
*/}}
{{- define "deephealth-backend.common-env" -}}
- name: DJANGO_ENV
  value: "/app/config"
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "deephealth-backend.fullname" . }}-postgresql
      key: postgresql-password
- name: RABBITMQ_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "deephealth-backend.fullname" . }}-rabbitmq
      key: rabbitmq-password
- name: DATABASE_URL
  value: psql://{{ .Values.postgresql.postgresqlUsername }}:$(POSTGRES_PASSWORD)@{{ include "deephealth-backend.fullname" . }}-postgresql:{{ .Values.postgresql.service.port }}/{{ .Values.postgresql.postgresqlDatabase }}
- name: CELERY_RESULT_BACKEND
  value: db+postgresql://{{ .Values.postgresql.postgresqlUsername }}:$(POSTGRES_PASSWORD)@{{ include "deephealth-backend.fullname" . }}-postgresql:{{ .Values.postgresql.service.port }}/{{ .Values.postgresql.postgresqlDatabase }}
- name: RABBITMQ_BROKER_URL
  value: amqp://{{ .Values.broker.rabbitmq.username }}:$(RABBITMQ_PASSWORD)@{{ include "deephealth-backend.fullname" . }}-rabbitmq:{{ .Values.broker.service.port }}
{{- end -}}


{{/*
Define mount paths for shared volumes variables in connection between some pods.
*/}}
{{- define "deephealth-backend.common-mount-paths" -}}
- name: backend-secrets
  mountPath: "/app/config"
  subPath: config
- name: datasets-volume
  mountPath: {{ .Values.persistence.datasets.path }}
- name: training-volume
  mountPath: {{ .Values.persistence.training.path }}
- name: inference-volume
  mountPath: {{ .Values.persistence.inference.path }}
{{- end -}}


{{/*
Define shared volumes in connection between some pods.
*/}}
{{- define "deephealth-backend.common-volumes" -}}
- name: backend-secrets
  secret:
    secretName: {{ include "deephealth-backend.fullname" . }}-secrets
    defaultMode: 0644
- name: datasets-volume
  persistentVolumeClaim:
    {{ if .Values.backend.persistence.datasets.existingClaim }}
    claimName: {{ .Values.backend.persistence.datasets.existingClaim }}
    {{ else }}
    claimName: data-{{ include "deephealth-backend.fullname" . }}-datasets
    {{ end }}
    readOnly: false
- name: training-volume
  persistentVolumeClaim:
    {{ if .Values.backend.persistence.training.existingClaim }}
    claimName: {{ .Values.backend.persistence.training.existingClaim }}
    {{ else }}
    claimName: data-{{ include "deephealth-backend.fullname" . }}-training
    {{ end }}
    readOnly: false
- name: inference-volume
  persistentVolumeClaim:
    {{ if .Values.backend.persistence.inference.existingClaim }}
    claimName: {{ .Values.backend.persistence.inference.existingClaim }}
    {{ else }}
    claimName: data-{{ include "deephealth-backend.fullname" . }}-inference
    {{ end }}
    readOnly: false
{{- end -}}