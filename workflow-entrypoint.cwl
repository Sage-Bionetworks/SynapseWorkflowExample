#!/usr/bin/env cwl-runner
#
# Sample workflow
# Inputs:
#   submissionId: ID of the Synapse submission to process
#   adminUploadSynId: ID of a folder accessible only to the submission queue administrator
#   submitterUploadSynId: ID of a folder accessible to the submitter
#
cwlVersion: v1.0
class: Workflow

# the sole input for any Synapse-centric workflow is the submission id
inputs:
  - id: submissionId
    type: int
  - id: adminUploadSynId
    type: string
  - id: submitterUploadSynId
    type: string
  - id: workflowSynapseId
    type: string

# there are no output at the workflow engine level.  Everything is uploaded to Synapse
outputs: []

steps:
  downloadSubmission:
    run: downloadSubmissionFile.cwl
    in:
      - id: submissionId
        source: "#submissionId"
      - id: downloadLocation
        valueFrom: .
    out:
      - id: filePath
      - id: entity
      
  readWorkflowParameters:
    run:  job_file_reader_tool_yaml_sample.cwl
    in:
      - id: inputfile
        source: "#downloadSubmission/filePath"
    out:
      - id: message

  coreWorkflow:
    run: sample-workflow.cwl
    in:
      - id: message
        source: "#readWorkflowParameters/message"
    out:
      - id: stdout
  
  uploadResults:
    run: uploadToSynapse.cwl
    in:
      - id: infile
        source: "#coreWorkflow/stdout"
      - id: parentId
        source: "#submitterUploadSynId"
      - id: usedEntity
        source: "#downloadSubmission/entity"
      - id: executedEntity
        valueFrom: "#workflowSynapseId"
    out:
      - id: uploadedFileId
      - id: uploadedFileVersion
      
  annotateSubmissionWithOutput:
    run: annotateSubmission.cwl
    in:
      - id: submissionId
        source: "#submissionId"
      - id: annotationName
        valueFrom:  "workflowOutputFile"
      - id: annotationValue
        source: "#uploadResults/uploadedFileId"
      - id: private
        valueFrom: "false"
    out: []
 