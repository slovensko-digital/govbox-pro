class MessageThreadsTableRowComponent < ViewComponent::Base
  def initialize(message_thread:)
    @message_thread = message_thread
    # TODO - toto je otazka ci vlastne chceme vytahovat, lebo moze byt viac ako jedna spravna odpoved. A najma to bude neefektivne tu. Ked, tak dorobit do extrahujuceho jobu
    # toto je len velmi skaredy pokus o vytiahnutie toho, s kym komunikujeme ...
    @with_whom = @message_thread.messages.first.recipient_name || @message_thread.messages.first.sender_name
  end
end
