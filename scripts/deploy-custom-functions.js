const async = require('async')
const { randomUUID } = require('crypto')
const fs = require('fs-extra')
const glob = require('glob')
const fetch = require('node-fetch')
const path = require('path')
const tar = require('tar-stream')
const util = require('util')
const globPromise = util.promisify(glob.glob)
const pack = tar.pack()

// Required configuration
const HDB_INSTANCE_NAME = 'hub'
const HDB_ACCOUNT = 'makvoid'
const HDB_USERNAME = 'clusteradm'
const HDB_PASSWORD = '...'
const HDB_PROJECT_NAME = 'api-gateway'

// Defaults
const HDB_API_URL = `https://${HDB_INSTANCE_NAME}-${HDB_ACCOUNT}.harperdbcloud.com`
const ENCODED_CREDENTIALS = Buffer.from(`${HDB_USERNAME}:${HDB_PASSWORD}`).toString('base64')
const HDB_CUSTOM_FUNCTION_DIRECTORY = path.resolve(__dirname, '../custom-functions')

// Change working directory
process.chdir(HDB_CUSTOM_FUNCTION_DIRECTORY)

const main = async () => {
  // Find all files (no directories) within the Custom Functions directory
  const files = await globPromise('**/*.*', { nodir: true })
  console.log('Found a total of', files.length, 'files to add to the archive.')

  // Iterate through each file and add it to the archive
  await async.each(files, async (name) => {
    // Read the file contents
    let fileContents
    try {
      fileContents = await fs.promises.readFile(name, 'utf-8')
    } catch (e) {
      console.error(e)
      process.exit(1)
    }
    pack.entry({ name }, fileContents)
  })

  // Craft the deployment request
  const operation = {
    operation: 'deploy_custom_function_project',
    project: HDB_PROJECT_NAME,
    file: `/tmp/${randomUUID()}.tar`,
    payload: pack.read().toString('base64')
  }

  // Attempt to upload the package
  let request
  let result
  try {
    console.log('Deploying the project to HarperDB, please wait...')
    request = await fetch(HDB_API_URL, {
      method: 'POST',
      body: JSON.stringify(operation),
      headers: {
        Authorization: `Basic ${ENCODED_CREDENTIALS}`,
        'Content-Type': 'application/json'
      }
    })
    result = await request.json()
  } catch (e) {
    console.error('Error: Status', request.status, request.statusText)
    console.error(e)
    if (request.status === 502) {
      console.error('Even though this error has occurred, the project has most likely still been deployed.')
    }
    return
  }

  // Display results of operation
  console.log('Deployment has finished -', result.error ? result.error : result.message)
  process.exit(result.error ? 1 : 0)
}
main()
