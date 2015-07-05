for k, v of process.env
    module.exports[k] = v

module.exports.API_ROOT = process.env.SERVICE_URL or 'http://welcome.boardthreads.com'
