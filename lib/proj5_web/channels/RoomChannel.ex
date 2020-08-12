defmodule Proj5Web.RoomChannel do
	use Phoenix.Channel

	def join("room:lobby", _msg, socket) do
		{:ok, socket}
	end

	def join(_room, _params, _socket) do
		{:error, %{reason: "join error!!"}}
	end

	def handle_in("signUp", %{"username" => username, "password" => password}, socket) do
		res = Server.signup(username, password)
		if res == true do
			push socket, "signUpSuccess", %{body: "Sign up success"}
		else
			push socket, "signUpFail", %{body: "User already exists"}
		end
		flag = socket.assigns[:username]
		socket = if flag == nil do
			assign(socket, :username, username)
		else
			socket
		end

		{:noreply, socket}
	end

	def handle_in("login", %{"username" => username, "password" => password}, socket) do
		res = Server.login(username, password)
		if res == 0 do
        	push socket, "loginFail", %{body: "User not register"}
      	end
      	if res == 1 do
        	push socket, "loginFail", %{body: "User already login"}
      	end
      	if res == 2 do
      		:ets.insert(:socketMap, {socket, username})
        	push socket, "loginSuccess", %{body: "Login success"}
      	end
      	if res == 3 do
        	push socket, "loginFail", %{body: "Incorrect password"}
      	end
      	{:noreply, socket}
	end

	def handle_in("tweet", %{"tweetContent" => tweetContent, "tagsContent" => tagsContent, "mentionsContent" => mentionsContent}, socket) do
		username = socket.assigns[:username]

		flag = :ets.lookup(:userLoginMap, username)
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				content = tweetContent
				tags = String.split(tagsContent)
				mentions = String.split(mentionsContent)

				res = Server.tweet(username, content, tags, mentions)
				if res == false do
					push socket, "tweetResult", %{body: "Mentions contain invalid user"}
				else
					liveUsersInfo = :ets.match(:socketMap, {:"$1", :"_"})
					Enum.map(liveUsersInfo, fn each ->
						userSocket = Enum.at(each, 0)
						info = :ets.lookup(:socketMap, userSocket)
						if info != [] && judge(elem(Enum.at(info, 0), 1)) == true do
							push userSocket, "liveTweet", %{body: res}
						end

					end)
					push socket, "tweetResult", %{body: "You have sent a tweet"}
				end
			end
		end
		{:noreply, socket}
	end

	def judge(user) do
		info = :ets.lookup(:userLoginMap, user)
		res = if info == [] do
			false
		else
			status = elem(Enum.at(info, 0), 1)
			status
		end
	end

	def handle_in("reTweet", %{"reTweetContent" => reTweetContent}, socket) do
		username = socket.assigns[:username]


		flag = :ets.lookup(:userLoginMap, username)
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				tweetID = reTweetContent
				tweetInfo = :ets.lookup(:tweetIDMap, tweetID)
				IO.inspect tweetID
				res = Server.retweet(username, tweetID)
				if res == false do
					push socket, "tweetResult", %{body: "Tweet ID is invalid"}
				else
					liveUsersInfo = :ets.match(:socketMap, {:"$1", :"_"})
					Enum.map(liveUsersInfo, fn each ->
						userSocket = Enum.at(each, 0)
						info = :ets.lookup(:socketMap, userSocket)
						if info != [] && judge(elem(Enum.at(info, 0), 1)) == true do
							push userSocket, "liveTweet", %{body: res}
						end
					end)
					push socket, "tweetResult", %{body: "You have re-tweeted"}
				end
			end
		end


		{:noreply, socket}
	end

	def handle_in("follow", %{"followContent" => followContent}, socket) do
		username = socket.assigns[:username]

		flag = :ets.lookup(:userLoginMap, username)
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				res = Server.follow(username, followContent)
				if res == true do
					push socket, "followResult", %{body: "You follow #{followContent} success"}
				else
					push socket, "followResult", %{body: "The user you are following doesn't exsit"}
				end
			end
		end
		{:noreply, socket}
	end

	def handle_in("querySubscribe", _para, socket) do
		username = socket.assigns[:username]

		flag = :ets.lookup(:userLoginMap, username)
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				res = Server.querySubscribe(username)
				Enum.map(res, fn tmp ->
					Enum.map(tmp, fn each ->
						push socket, "queryResponse", %{body: each}
					end)
				end)
			end
		end
		{:noreply, socket}
	end

	def handle_in("queryTag", %{"queryTagContent" => queryTagContent}, socket) do
		username = socket.assigns[:username]

		flag = :ets.lookup(:userLoginMap, username)
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				res = Server.queryTag(username, queryTagContent)
				Enum.map(res, fn each ->
					push socket, "queryResponse", %{body: each}
				end)
			end
		end
		{:noreply, socket}
	end

	def handle_in("queryMention", _para, socket) do
		username = socket.assigns[:username]
		flag = :ets.lookup(:userLoginMap, username)
		IO.inspect flag
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				res = Server.queryMention(username)
				Enum.map(res, fn each ->
					push socket, "queryResponse", %{body: each}
				end)
			end
		end
		{:noreply, socket}
	end

	def handle_in("logOff", _para, socket) do
		username = socket.assigns[:username]

		flag = :ets.lookup(:userLoginMap, username)
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				:ets.delete(:socketMap, socket)
				:ets.insert(:userLoginMap, {username, false})
				push socket, "loginSuccess", %{body: "#{username} log out"}
			end
		end
		{:noreply, socket}
	end

	def handle_in("deleteAccount", _para, socket) do
		username = socket.assigns[:username]
		flag = :ets.lookup(:userLoginMap, username)
		if flag == [] do
			push socket, "loginFail", %{body: "Please login first"}
		else
			if elem(Enum.at(flag, 0), 1) == false do
				push socket, "loginFail", %{body: "Please login first"}
			else
				:ets.delete(:userMap, username)
				:ets.delete(:userLoginMap, username)
				:ets.delete(:userTweetMap, username)
				:ets.delete(:userSubscribeMap, username)
				:ets.delete(:mentionMap, username)
			end
		end
		{:noreply, socket}
	end
end

defmodule Server do
	def getCount() do
      countInfo = :ets.lookup(:cnt, :count)
      count = elem(Enum.at(countInfo, 0), 1)
      :ets.insert(:cnt, {:count, count + 1})
      count
    end

	def getPassword(username) do
		userInfo = :ets.lookup(:userMap, username)
		password = elem(Enum.at(userInfo, 0), 1)
	end

	def ifMentionExist(mentions) do
      res = Enum.reduce_while(mentions, true, fn user, acc ->
        flag = :ets.lookup(:userMap, user)
        if flag == [] do
          {:halt, false}
        else
          {:cont, true}
        end
      end)
    end

    def ifTagExist(tag) do
      flag = :ets.lookup(:tagMap, tag)
      if flag == [] do
        false
      else
        true
      end
    end

    def ifUserExist(mention) do
      flag = :ets.lookup(:mentionMap, mention)
      if flag == [] do
        false
      else
        true
      end
    end

    def getTweetListByTag(tag) do
      tweetInfo = :ets.lookup(:tagMap, tag)
      tweetList = elem(Enum.at(tweetInfo, 0), 1)
    end

    def getTweetListByMention(mention) do
      tweetInfo = :ets.lookup(:mentionMap, mention)
      tweetList = elem(Enum.at(tweetInfo, 0), 1)
    end

    def concatToString(list, res, index) do
      len = length(list)
      res = if index < len do
        concatToString(list, res <> " #{Enum.at(list, index)}", index + 1)
      else
        res
      end
    end

	def signup(username, password) do
	  flag = :ets.lookup(:userMap, username)
      res = if flag != [] do
        false
      else
        :ets.insert_new(:userMap, {username, password})
        :ets.insert_new(:userLoginMap, {username, false})
        :ets.insert_new(:userTweetMap, {username, []})
        :ets.insert_new(:userSubscribeMap, {username, MapSet.new()})
        :ets.insert_new(:mentionMap, {username, []})
        true
      end
	end

	def login(username, password) do
      flag1 = :ets.lookup(:userMap, username)
      res = if flag1 == [] do
        IO.puts "not register"
        0
      else
        flag2 = :ets.lookup(:userLoginMap, username)
        if flag2 == true do
          IO.puts "already login"
          1
        else
          correctPassword = getPassword(username)
          if password == correctPassword do
            :ets.insert(:userLoginMap, {username, true})
            2
            # IO.puts "login"
          else
            IO.puts "incorrect password"
            3
          end
        end
      end
    end

    def tweet(username, content, tags, mentions) do
      len = length(mentions)
      flag = ifMentionExist(mentions)
      IO.puts flag
      res = if len != 0 && ifMentionExist(mentions) == false do
        IO.puts "mention user doesn't exist"
        false
      else
        #Update tweet with global ID
        count = getCount()
        #Update userTweetMap
        tweetInfo = :ets.lookup(:userTweetMap, username)
        tweetList = elem(Enum.at(tweetInfo, 0), 1)
        newTweet = [username, count, content, tags, mentions, true]
        tweetList = List.insert_at(tweetList, 0, newTweet)
        :ets.insert(:userTweetMap, {username, tweetList})
        :ets.insert(:tweetIDMap, {"#{count}", newTweet})
        #Update tagMap
        Enum.map(tags, fn tag ->
          if ifTagExist(tag) == true do
            tweetList = getTweetListByTag(tag)
            tweetList = List.insert_at(tweetList, 0, newTweet)
            :ets.insert(:tagMap, {tag, tweetList})
          else
            :ets.insert(:tagMap, {tag, [newTweet]})
          end
        end)
        #Update mentionMap
        Enum.map(mentions, fn mention ->
          if ifUserExist(mention) == true do
            tweetList = getTweetListByMention(mention)
            tweetList = List.insert_at(tweetList, 0, newTweet)
            :ets.insert(:mentionMap, {mention, tweetList})
          else
            :ets.insert(:mentionMap, {mention, [newTweet]})
          end
        end)
        buffer = "user: #{username}, tweetID: #{count}, content: #{content}, tags:"
        buffer = concatToString(tags, buffer, 0)
        buffer = buffer <> ", mention: "
        buffer = concatToString(mentions, buffer, 0)
        buffer
      end
    end

    def follow(username, subscribeWho) do
      flag = :ets.lookup(:userMap, subscribeWho)
      if flag != [] do
        subscribeInfo = :ets.lookup(:userSubscribeMap, username)
        subscribeSet = elem(Enum.at(subscribeInfo, 0), 1)
        subscribeSet = MapSet.put(subscribeSet, subscribeWho)
        :ets.insert(:userSubscribeMap, {username, subscribeSet})
        true
      else
        false
      end
    end

    def retweet(username, tweetID) do
      tweetInfo = :ets.lookup(:tweetIDMap, tweetID)
      if tweetInfo == [] do
        IO.puts "tweetID invalid"
        false
      else
        tweet = elem(Enum.at(tweetInfo, 0), 1)
        tweet = List.replace_at(tweet, 5, false)
        #Update user tweet map
        # tweetInfo = :ets.lookup(:userTweetMap, username)
        # tweetList = elem(Enum.at(tweetInfo, 0), 1)
        # tweetList = List.insert_at(tweetList, -1, tweet)
        # :ets.insert(:userTweetMap, {username, tweetList})
        buffer = "user: #{username}, RETWEET: tweetID: #{Enum.at(tweet, 0)}, content: #{Enum.at(tweet, 1)}, tags:"
        buffer = concatToString(Enum.at(tweet, 3), buffer, 0)
        buffer = buffer <> ", mentions: "
        buffer = concatToString(Enum.at(tweet, 4), buffer, 0)
        buffer
      end
    end

    def querySubscribe(username) do
      	subscribeSet = Enum.at(:ets.match(:userSubscribeMap, {username, :"$1"}), 0)
  		subscribeSet = Enum.at(subscribeSet, 0)
  		userList = []
  		userList = Enum.map(subscribeSet, fn each ->
  			userList ++ each
  		end)

  		tweetList = []
  		tweetList = getUserTweets(userList, tweetList, 0)
  		tmp1 = []
  		tmp1 = transfer1(tweetList, tmp1, 0)
    end

    def listToStringList(list, res, index) do
  		len = length(list)
  		if index < len do
  			tweet = Enum.at(list, index)
  			buffer = tweetElesToString(tweet)
  			listToStringList(list, List.insert_at(res, 0, buffer), index + 1)
  		else
  			res
  		end
  	end

  	def tweetElesToString(tweet) do
  		username = Enum.at(tweet, 0)
  		no = Enum.at(tweet, 1)
  		content = Enum.at(tweet, 2)
  		tags = Enum.at(tweet, 3)
  		mentions = Enum.at(tweet, 4)
  		buffer = "user:#{username}, tweetID:#{no}, content:#{content}, tags:"
  		buffer = concatToString(tags, buffer, 0)
  		buffer = buffer <> "mentions:"
  		buffer = concatToString(mentions, buffer, 0)
  		buffer
  	end

    def getUserTweets(list, res, index) do
  		len = length(list)
  		if index < len do
  			user = Enum.at(list, index)
  			tweetInfo = :ets.lookup(:userTweetMap, user)
  			tweets = elem(Enum.at(tweetInfo, 0), 1)
  			res = List.insert_at(res, -1, tweets)
  			getUserTweets(list, res, index + 1)
  		else
  			res
  		end
  	end

  	def transfer1(list, res, index) do
  		len = length(list)
  		if index < len do
  			tweetList = Enum.at(list, index)
  			tmp = []
  			tmp = listToStringList(tweetList, tmp, 0)
  			res = List.insert_at(res, -1, tmp)
  			transfer1(list, res, index + 1)
  		else
  			res
  		end
  	end

    def queryTag(username, tag) do
    	flag = :ets.lookup(:tagMap, tag)
  		res = if flag != [] do
  			elem(Enum.at(flag, 0), 1)
  		else
  			[]
  		end

  		buffers = []
  		buffers = listToStringList(res, buffers, 0)
  		buffers
    end

    def queryMention(username) do
    	flag = :ets.lookup(:mentionMap, username)
  		res = if flag != [] do
  			elem(Enum.at(flag, 0), 1)
  		else
  			[]
  		end
  		buffers = []
  		buffers = listToStringList(res, buffers, 0)
  		buffers
    end
end
