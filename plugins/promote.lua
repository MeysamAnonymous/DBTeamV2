local function run(msg, matches)

	if matches[1] == "admin" then
		if permissions(msg.from.id, msg.to.id, "promote_admin") then
			if msg.reply_id then
				redis:sadd('admins', msg.replied.id)
				redis:srem('mods:'..msg.to.id, msg.replied.id)
				send_msg(msg.to.id, lang_text(msg.to.id, 'newAdmin') .. ": @" .. (msg.replied.username or msg.replied.first_name), "html")
			elseif matches[2] then
				resolve_username(matches[2], resolve_cb, {chat_id = msg.to.id, superior = msg.from.id, plugin_tag = "promote_admin", command = "admin"})
			end
		end
	elseif matches[1] == "mod" then
		if permissions(msg.from.id, msg.to.id, "promote_mod") then
			if msg.reply_id then
				redis:sadd('mods:'..msg.to.id, msg.replied.id)
				if new_is_sudo(msg.from.id) then
					redis:srem('admins', msg.replied.id)
				end
				send_msg(msg.to.id, lang_text(msg.to.id, 'newMod') .. ": @" .. (msg.replied.username or msg.replied.first_name), "html")
			elseif matches[2] then
				resolve_username(matches[2], resolve_cb, {chat_id = msg.to.id, superior = msg.from.id, plugin_tag = "promote_mod", command = "mod"})
			end
		end
	elseif matches[1] == "user" then
		if permissions(msg.from.id, msg.to.id, "promote_user") then
			if msg.reply_id then
				if new_is_sudo(msg.from.id) then
					redis:srem('mods:'..msg.to.id, msg.replied.id)
					redis:srem('admins', msg.replied.id)
				elseif is_admin(msg.to.id) then
					redis:srem('mods:'..msg.to.id, msg.replied.id)
				end
				send_msg(msg.to.id, "<code>></code> @" .. (msg.replied.username or msg.replied.first_name) .. "" ..  lang_text(msg.to.id, 'nowUser'), "html")
			elseif matches[2] then
				resolve_username(matches[2], resolve_cb, {chat_id = msg.to.id, superior = msg.from.id, plugin_tag = "promote_user", command = "user"})
			end
		end
	elseif matches[1] == "admins" then
		if permissions(msg.from.id, msg.to.id, "promote_user") then
			local text = "<b>Admins:</b>\n"
			for k, v in pairs(redis:smembers("admins")) do
				text = text .. "<code>></code> " .. redis:hget('bot:ids', v) .. " <code>(" .. v .. ")</code>\n"
			end
			send_msg(msg.to.id, text, 'html')
		end
	elseif matches[1] == "mods" then
		if permissions(msg.from.id, msg.to.id, "promote_user") then
			local text = "<b>Mods:</b>\n"
			for k, v in pairs(redis:smembers("mods:" .. msg.to.id)) do
				text = text .. "<code>></code> " .. redis:hget('bot:ids', v) .. " <code>(" .. v .. ")</code>\n"
			end
			send_msg(msg.to.id, text, 'html')
		end
	elseif matches[1] == "users" or matches[1] == "members" or matches[1] == "tagall" then
		if permissions(msg.from.id, msg.to.id, "tagall") then
			if matches[2] then
				getChannelMembers(msg.to.id, 0, 'Recent', 200, members_cb, {chat = msg.to.id, text = matches[2]})
			else
				getChannelMembers(msg.to.id, 0, 'Recent', 200, members_cb, {chat = msg.to.id, text = nil})
			end
		end	
	elseif matches[1] == "bots" then
		if permissions(msg.from.id, msg.to.id, "tagall") then --------translations
			getChannelMembers(msg.to.id, 0, 'Bots', 200, bots_cb, msg.to.id)
		end
	elseif matches[1] == "kicked" then
		if permissions(msg.from.id, msg.to.id, "tagall") then--------translations
			getChannelMembers(msg.to.id, 0, 'Kicked', 200, kicked_cb, msg.to.id)
		end
	elseif matches[1] == "banall" then
		if permissions(msg.from.id, msg.to.id, "banall") then--------translations
			getChannelMembers(msg.to.id, 0, 'Recent', 200, banall_cb, msg.to.id)
		end
	elseif matches[1] == "leave" then
		if permissions(msg.from.id, msg.to.id, "leave") then--------translations
			send_msg(msg.to.id, "<b>Bye!</b>", 'html')------translations
			kick_user(msg.to.id, _config.our_id[1])
		end
	elseif matches[1] == "setabout" and matches[2] then
		if permissions(msg.from.id, msg.to.id, "setabout") then--------translations
			changeAbout(matches[2], ok_cb)
			send_msg(msg.to.id, "<b>About changed to:</b>" .. matches[2], 'html')------translations
		end			
	end
end

function members_cb(extra, data)
	openChat(msg.to.id, opencb)
	local count = data.total_count_
	if not count then
		send_msg(extra.chat, "<b>Error:</b> must be a supergroup.", 'html')
	end
	local count2 = count
	text = "<b>Chat users (</b>"..count.."<b>):</b> \n"
	for k,v in pairs(data.members_) do
		if v.user_id_ then	
			count2 = count2 - 1	
			resolve_id(v.user_id_, resolveid_cb, {userid = v.user_id_ , send = count2, chat = extra.chat, text = extra.text})
		end
	end
end

function banall_cb(extra, data)
	send_msg(extra, "<b>Trying to ban all users...</b>", 'html')------translations
	for k,vv in pairs(data.members_) do
		for v,user in pairs(_config.sudo_users) do
			if vv.user_id_ ~= user and  vv.user_id_ ~= _config.our_id[1] then
				kick_user(extra, vv.user_id_)		
			end
		end
	end
end

function bots_cb(extra, data)
	local count = data.total_count_
	local count2 = count
	text = "<b>Bots in chat (</b>"..count.."<b>):</b> \n"
	for k,v in pairs(data.members_) do
		if v.user_id_ then	
			count2 = count2 - 1	
			resolve_id(v.user_id_, resolveid_cb, {userid = v.user_id_ , send = count2, chat = extra, text = nil})
		end
	end
end

function kicked_cb(extra, data)
	local count = data.total_count_
	if not count then
		send_msg(extra, "<b>Error:</b> must be a supergroup and admin of the chat.", 'html')
	end
	local count2 = count
	text = "<b>Banned users in chat (</b>"..count.."<b>):</b> \n"
	for k,v in pairs(data.members_) do
		if v.user_id_ then	
			count2 = count2 - 1
			resolve_id(v.inviter_user_id_, resolveid_kicked_cb, {userid = v.inviter_user_id_ , send = count2, chat = extra, status = "kicker", idkicked = v.user_id_})
		end
	end
end

function resolveid_kicked_cb(extra,info)
	if extra.status == "kicker" then
		if info.user_.username_ then
			info_from_kicker  = '<code>></code>@'..info.user_.username_..' '
		else
			info_from_kicker  = '<code>></code>'..info.user_.first_name_..' '
		end
		resolve_id(extra.idkicked, resolveid_kicked_cb, {userid = extra.idkicked , send = extra.send, chat = extra.chat, status = "kicked", infokicker = info_from_kicker })		
	else
		if info.user_.username_ then
			text  = text..extra.infokicker..'banned @'..info.user_.username_..'\n'
		else
			text  = text..extra.infokicker..'banned '..info.user_.first_name_..'\n'
		end
		if extra.send == 0 then
			send_msg(extra.chat, text, 'html')
		end
	end
end

function resolveid_cb(extra,info)
	if info.user_.username_ then
		text  = text..'<code>></code> @'..info.user_.username_.."<code>("..extra.userid..')</code>\n'
	else
		text  = text..'<code>></code> '..info.user_.first_name_.."<code>("..extra.userid..')</code>\n'
	end
	
	if extra.send == 0 then
		if extra.text then	
			text  = text..'\n<b>'..extra.text..'</b>'
			send_msg(extra.chat, text, 'html')
		else
		text  = text
			send_msg(extra.chat, text, 'html')
		end
	end
end



return {
  patterns = {
  	"^[!/#](admin)$",
	"^[!/#](admin) (.*)$",
    "^[!/#](mod)$",
	"^[!/#](mod) (.*)$",
    "^[!/#](user)$",
	"^[!/#](user) (.*)$",
    "^[!/#](admins)$",
    "^[!/#](mods)$",
	"^[!/#](users)$",
	"^[!/#](members)$",
	"^[!/#](tagall)$",
	"^[!/#](users) (.*)$",
	"^[!/#](members) (.*)$",
	"^[!/#](tagall) (.*)$",
	"^[!/#](bots)$",
	"^[!/#](kicked)$",
	"^[!/#](banall)$",
	"^[!/#](leave)$",
	"^[!/#](setabout) (.*)$",
  },
  run = run
}