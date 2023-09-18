module Common
  class TagSelectorPopupComponent < ViewComponent::Base
    def initialize(object)
      @object = object
      # TODO: Toto bude treba tiez prestahovat niekam inam. Len je to zas hlboko
      @tags = Current.tenant.tags.where.not(id: object.tags.ids).where(visible: true)
        .where(id: TagGroup.select(:tag_id).joins(:group, :tag, group: :users)
          .where(group: { tenant_id: Current.tenant.id }, tag: { tenant_id: Current.tenant.id }, users: { id: Current.user.id })
        )
    end
  end
end
