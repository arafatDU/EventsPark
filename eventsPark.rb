require 'securerandom'
require 'json'

class Event
  attr_accessor :id, :name, :description, :date, :location, :attendees

  def initialize(name, description, date, location)
    @id = SecureRandom.uuid
    @name = name
    @description = description
    @date = date
    @location = location
    @attendees = []
  end

  def to_json(*args)
    {
      id: @id,
      name: @name,
      description: @description,
      date: @date,
      location: @location,
      attendees: @attendees
    }.to_json(*args)
  end

  def self.from_json(json)
    data = JSON.parse(json)
    event = Event.new(data['name'], data['description'], data['date'], data['location'])
    event.id = data['id']
    event.attendees = data['attendees']
    event
  end

  def add_attendee(user)
    @attendees << user.id
    update_events_file
  end

  def participants_for_event
    @attendees
  end

  private

  def update_events_file
    events_data = []

    File.open('events.json', 'r') do |file|
      events_data = JSON.parse(file.read)
    end

    events_data.each do |event_data|
      if event_data['id'] == @id
        event_data['attendees'] = @attendees
        break
      end
    end

    File.open('events.json', 'w') do |file|
      file.write(JSON.pretty_generate(events_data))
    end
  end
end


class User
  attr_accessor :id, :name, :email, :password, :participated_events

  def initialize(name, email, password)
    @id = SecureRandom.uuid
    @name = name
    @email = email
    @password = password
    @participated_events = []
  end

  def to_json(*args)
    {
      id: @id,
      name: @name,
      email: @email,
      password: @password,
      participated_events: @participated_events
    }.to_json(*args)
  end

  def self.from_json(json)
    data = JSON.parse(json)
    user = User.new(data['name'], data['email'], data['password'])
    user.id = data['id']
    user.participated_events = data['participated_events']
    user
  end

  def add_participated_event(event_id)
    @participated_events << event_id
    update_users_file
  end

  private

  def update_users_file
    users_data = []

    File.open('users.json', 'r') do |file|
      users_data = JSON.parse(file.read)
    end

    users_data.each do |user_data|
      if user_data['id'] == @id
        user_data['participated_events'] = @participated_events
        break
      end
    end

    File.open('users.json', 'w') do |file|
      file.write(JSON.pretty_generate(users_data))
    end
  end
end


class Admin
  attr_accessor :name, :password

  def initialize(name, password)
    @name = name
    @password = password
  end
end

class EventManagementSystem
  attr_accessor :events, :users, :admin

  def initialize
    load_users_from_file('users.json')
    load_events_from_file('events.json')
    @admin = Admin.new("admin", "admin123")  # Default admin credentials
  end

  def load_users_from_file(filename)
    @users = []

    if File.zero?(filename)  # Check if the file is empty
      #puts "Users file is empty. Initializing users array as empty."
      return
    end

    begin
      File.open(filename, 'r') do |file|
        data = file.read
        unless data.empty?
          @users = JSON.parse(data).map { |user_data| User.from_json(user_data) }
        end
      end
    rescue JSON::ParserError => e
      #puts "Error parsing users file: #{e.message}. Initializing users array as empty."
      @users = []
    end
  end


  def load_events_from_file(filename)
    @events = []

    if File.zero?(filename)  # Check if the file is empty
      #puts "Events file is empty. Initializing events array as empty."
      return
    end

    begin
      File.open(filename, 'r') do |file|
        data = file.read
        unless data.empty?
          @events = JSON.parse(data).map { |event_data| Event.from_json(event_data) }
        end
      end
    rescue JSON::ParserError => e
      #puts "Error parsing events file: #{e.message}. Initializing events array as empty."
      @events = []
    end
  end


  def save_users_to_file(filename)
    File.open(filename, 'w') do |file|
      file.puts JSON.generate(@users.map(&:to_json))
    end
  end

  def save_events_to_file(filename)
    File.open(filename, 'w') do |file|
      file.puts JSON.generate(@events.map(&:to_json))
    end
  end

  def create_event(name, description, date, location)
    event = Event.new(name, description, date, location)
    @events << event
    save_events_to_file('events.json')
    event
  end

  def register_user(name, email, password)
    user = User.new(name, email, password)
    @users << user
    save_users_to_file('users.json')
    user
  end

  def login_user(email, password)
    @users.find { |user| user.email == email && user.password == password }
  end

  def login_admin(name, password)
    @admin if @admin.name == name && @admin.password == password
  end

  def sign_up_for_event(event_id, user)
    event = find_event(event_id)
    return unless event

    event.add_attendee(user)
    user.add_participated_event(event_id)
    puts "#{user.name} successfully signed up for #{event.name}!"
  end

  def find_event(event_id)
    @events.find { |event| event.id == event_id }
  end
end

class Dashboard
  attr_accessor :event_management_system, :current_user, :logged_in_admin

  def initialize
    @event_management_system = EventManagementSystem.new
    @current_user = nil
    @logged_in_admin = false
  end

  def run
    loop do
      display_dashboard
    end
  end

  private

  def display_dashboard
    system('clear') || system('cls')  # Clear console

    if @logged_in_admin
      display_admin_dashboard
    elsif @current_user
      display_user_dashboard
    else
      display_main_dashboard
    end
  end

  def display_main_dashboard
    puts "----------------------------------"
    puts "            EventsPark            "
    puts "----------------------------------"
    puts "Welcome To EventsPark"
    puts "----------------------------------"
    puts "Available Events:"
    @event_management_system.events.each do |event|
      puts "ID: #{event.id}, Name: #{event.name}, Date: #{event.date}"
      puts "Description: #{event.description}, Location: #{event.location}"
      puts "----------------------------------"
    end
    puts "----------------------------------"
    puts "Navbar:"
    if @current_user
      puts "1. Logout"
    else
      puts "1. Log in"
      puts "2. Sign Up"
    end
    puts "3. Admin Login"
    puts "4. Close"
    puts "----------------------------------"
    print "Enter your choice: "
    choice = gets.chomp.to_i

    case choice
    when 1
      if @current_user
        @current_user = nil
      else
        login
      end
    when 2
      sign_up
    when 3
      admin_login
    when 4
      exit_project
    else
      puts "Invalid choice. Please try again."
    end
  end

  def login
    print "Enter your email: "
    email = gets.chomp
    print "Enter your password: "
    password = gets.chomp

    @current_user = @event_management_system.login_user(email, password)

    if @current_user
      puts "Login successful!"
      sleep(2)  # Sleep for 2 seconds to display message
    else
      puts "Invalid email or password. Please try again."
      sleep(2)  # Sleep for 2 seconds to display message
    end
  end

  def sign_up
    print "Enter your name: "
    name = gets.chomp
    print "Enter your email: "
    email = gets.chomp
    print "Enter your password: "
    password = gets.chomp

    user = @event_management_system.register_user(name, email, password)
    @current_user = user
    puts "Sign up successful!"
    sleep(2)  # Sleep for 2 seconds to display message
  end

  def admin_login
    print "Enter admin username: "
    username = gets.chomp
    print "Enter admin password: "
    password = gets.chomp

    admin = @event_management_system.login_admin(username, password)

    if admin
      @logged_in_admin = true
      puts "Admin login successful!"
      sleep(2)  # Sleep for 2 seconds to display message
    else
      puts "Invalid admin credentials. Please try again."
      sleep(2)  # Sleep for 2 seconds to display message
    end
  end

  def display_user_dashboard
    puts "----------------------------------"
    puts "            EventsPark            "
    puts "----------------------------------"
    puts "Welcome back, #{@current_user&.name}"
    puts "----------------------------------"
    puts "Your Participated Events:"
    @current_user&.participated_events&.each do |event_id|
      event = @event_management_system.find_event(event_id)
      if event
        puts "#{event.id}: #{event.name} (#{event.date})"
      end
    end
    puts "----------------------------------"
    puts "Available Events:"
    @event_management_system.events.each do |event|
      puts "ID: #{event.id}, Name: #{event.name}, Date: #{event.date}"
      puts "Description: #{event.description}, Location: #{event.location}"
      puts "----------------------------------"
    end
    puts "----------------------------------"
    puts "Navbar:"
    puts "1. Participate in an Event"
    puts "2. Logout"
    puts "3. Close"
    puts "----------------------------------"
    print "Enter your choice: "
    choice = gets.chomp.to_i

    case choice
    when 1
      participate_in_event
    when 2
      @current_user = nil
    when 3
      exit_project
    else
      puts "Invalid choice. Please try again."
    end
  end

  def participate_in_event
    print "Enter the ID of the event you want to participate in: "
    event_id = gets.chomp
    event = @event_management_system.find_event(event_id)

    if event
      @event_management_system.sign_up_for_event(event_id, @current_user)
    else
      puts "Invalid event ID. Please try again."
    end
    sleep(2)  # Sleep for 2 seconds to display message
  end

  def display_admin_dashboard
    puts "----------------------------------"
    puts "            EventsPark            "
    puts "----------------------------------"
    puts "Welcome, Admin!"
    puts "----------------------------------"
    puts "Available Events:"
    @event_management_system.events.each do |event|
      puts "ID: #{event.id}, Name: #{event.name}, Date: #{event.date}"
      puts "Description: #{event.description}, Location: #{event.location}"
      puts "----------------------------------"
    end
    puts "----------------------------------"
    puts "Navbar:"
    puts "1. Create Event"
    puts "2. See User Participated Event"
    puts "3. Logout"
    puts "4. Close"
    puts "----------------------------------"
    print "Enter your choice: "
    choice = gets.chomp.to_i

    case choice
    when 1
      create_event
    when 2
      see_user_participated_event
    when 3
      @logged_in_admin = false
    when 4
      exit_project
    else
      puts "Invalid choice. Please try again."
    end
  end


  def create_event
    print "Enter event name: "
    name = gets.chomp
    print "Enter event description: "
    description = gets.chomp
    print "Enter event date (YYYY-MM-DD): "
    date = gets.chomp
    print "Enter event location: "
    location = gets.chomp

    event = @event_management_system.create_event(name, description, date, location)
    puts "Event created successfully!"
    sleep(2)  # Sleep for 2 seconds to display message
  end

  def see_user_participated_event
    loop do
      print "Enter the ID of the event you want to see the participants for (or 'b' to go back): "
      event_id = gets.chomp
      break if event_id.downcase == 'b'

      event = @event_management_system.find_event(event_id)

      if event
        participants = event.participants_for_event
        if participants.empty?
          puts "No users have participated in this event yet."
        else
          puts "Participants for Event #{event_id} (#{event.name}):"
          participants.each do |participant_id|
            participant = @event_management_system.users.find { |user| user.id == participant_id }
            if participant
              puts "#{participant.name} (#{participant.email})"
            end
          end
        end
      else
        puts "Invalid event ID. Please try again."
      end
    end
  end



  def exit_project
    puts "Exiting EventsPark. Goodbye!"
    exit
  end
end

def main
  dashboard = Dashboard.new
  dashboard.run
end

main if __FILE__ == $PROGRAM_NAME
