require 'aws-sdk'

module GemMiner
  # Handles all communication with SQS queues
  class GemMapQueue
    attr_writer :logger
    SQS_MAX_BATCH_SIZE = 10

    def initialize(queue_name = nil, logger = nil)
      setup_queue(queue_name) if queue_name
      @logger = logger
    end

    def setup_queue(queue_name)
      @sqs = Aws::SQS::Client.new(region: ENV['AWS_REGION'])
      @queue_url = @sqs.get_queue_url(queue_name: queue_name).queue_url
    rescue => e
      log_error(e, 'Could not connect to queue')
    end

    def log_error(ex, description)
      if @logger
        err = ex.is_a?(Aws::SQS::Errors::ServiceError) ? 'QUEUE_ERROR' : 'ERROR'
        @logger.error("#{err}: #{description}")
      else
        puts description
      end
      fail ex
    end

    def send_message(message)
      @sqs.send_message(queue_url: @queue_url, message_body: message)
    end

    def send_message_batch(message)
      message.each_slice(10) do |payload|
        i=0
        unit = payload.map do |item|
          i += 1
          {message_body: item.to_s, id: i.to_s}
        end
        @sqs.send_message_batch(queue_url: @queue_url, entries: unit)
      end
    end

    def messages_available
      attrs = @sqs.get_queue_attributes(
        queue_url: @queue_url,
        attribute_names: ['ApproximateNumberOfMessages']
      )
      attrs.attributes['ApproximateNumberOfMessages'].to_i
    rescue => e
      log_error(e, 'Could not get number of messages from queue')
    end

    def poll(&_message_handler)
      poller = Aws::SQS::QueuePoller.new(@queue_url)
      poller.poll(max_number_of_messages: batch_size,
                  wait_time_seconds: 0,
                  idle_timeout: 5) do |msg|
        yield msg.body
      end
    rescue => e
      log_error(e, 'Failed while polling queue')
    end

    def poll_batch(batch_size = SQS_MAX_BATCH_SIZE, &_message_handler)
      poller = Aws::SQS::QueuePoller.new(@queue_url)
      poller.poll(max_number_of_messages: batch_size,
                  wait_time_seconds: 0,
                  idle_timeout: 5) do |msgs|
        yield msgs.map(&:body)
      end
    rescue => e
      log_error(e, 'Failed while polling queue')
    end
  end
end

## Sample code
# q = GemMiner::GemMapQueue.new('GemMap')
#
# q.messages_available
#
# q.poll do |msg|
#  puts "MSG: #{msg}"
# end
#
# q.poll_batch do |msg|
#  puts "MSG: #{msg}"
# end
