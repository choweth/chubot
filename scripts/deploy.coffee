# Description:
#     Checks if we should deploy
#
# Commands:
#     should i|we deploy

brain_key = "deploy_vibe"

module.exports = (robot) ->
    initialize = () ->
        initialize_brain()
        setInterval(should_i_deploy_status, 5 * 60 * 1000)

    setTimeout(initialize, 5000)

    initialize_brain = () ->
        console.log("initializing brain for #{brain_key}")
        robot.brain.set(brain_key, {"status": "none", "description": "Why not?"})

    status_changed = (status) ->
        data = robot.brain.get(brain_key)
        return true if status.description != data["description"]
        return true if status.indicator != data["status"]
        return false

    update_status = (status) ->
        data = robot.brain.get(brain_key)
        data["status"] = status.indicator
        data["description"] = status.description

    should_i_deploy_status = (msg) ->
        should_i_deploy_url = "https://shouldideploy.today/api?tz=America/New_York"
        robot.http(should_i_deploy_url).get() (err, res, body) ->
            if res.statusCode is 200
                status = {"indicator": JSON.parse(body).shouldideploy, "description": JSON.parse(body).message}

                # only send the message if the status changes or a user requests it
                if not msg? and not status_changed(status)
                    console.log("skipping")
                    return

                update_status(status)

                if status.indicator == "true"
                    message = ":thumbsup:"
                else
                    message = ":fire:"

                message = "#{message} Deploy Vibe: #{status.description}"
                console.log(message)

                if msg?
                    msg.send message
                else
                    robot.messageRoom "temp", message
            else
                console.log("ERROR: failed to fetch status from shouldideploy.today: #{should_i_deploy_url}")

    robot.hear /should ?(?:i|we) deploy/i, (msg) ->
        should_i_deploy_status(msg)
