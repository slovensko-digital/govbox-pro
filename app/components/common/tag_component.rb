module Common
  class TagComponent < ViewComponent::Base
    def initialize(tag, classes="", color: nil)
      @label = tag.name || tag.external_name
      @classes = classes
      @color = tag.color || "gray"
      @icon = tag.icon.presence || (tag.gives_access? ? "key" : nil)
    end
  end
end

# NOTE: Tailwind processor catches these
# class="bg-slate-50 border-slate-400 text-slate-600 ring-slate-500/10"
# class="bg-gray-50 border-gray-400 text-gray-600 ring-gray-500/10"
# class="bg-zinc-50 border-zinc-400 text-zinc-600 ring-zinc-500/10"
# class="bg-neutral-50 border-neutral-400 text-neutral-600 ring-neutral-500/10"
# class="bg-stone-50 border-stone-400 text-stone-600 ring-stone-500/10"
# class="bg-red-50 border-red-400 text-red-600 ring-red-500/10"
# class="bg-orange-50 border-orange-400 text-orange-600 ring-orange-500/10"
# class="bg-amber-50 border-amber-400 text-amber-600 ring-amber-500/10"
# class="bg-yellow-50 border-yellow-400 text-yellow-600 ring-yellow-500/10"
# class="bg-lime-50 border-lime-400 text-lime-600 ring-lime-500/10"
# class="bg-green-50 border-green-400 text-green-600 ring-green-500/10"
# class="bg-emerald-50 border-emerald-400 text-emerald-600 ring-emerald-500/10"
# class="bg-teal-50 border-teal-400 text-teal-600 ring-teal-500/10"
# class="bg-cyan-50 border-cyan-400 text-cyan-600 ring-cyan-500/10"
# class="bg-sky-50 border-sky-400 text-sky-600 ring-sky-500/10"
# class="bg-blue-50 border-blue-400 text-blue-600 ring-blue-500/10"
# class="bg-indigo-50 border-indigo-400 text-indigo-600 ring-indigo-500/10"
# class="bg-violet-50 border-violet-400 text-violet-600 ring-violet-500/10"
# class="bg-purple-50 border-purple-400 text-purple-600 ring-purple-500/10"
# class="bg-fuchsia-50 border-fuchsia-400 text-fuchsia-600 ring-fuchsia-500/10"
# class="bg-pink-50 border-pink-400 text-pink-600 ring-pink-500/10"
# class="bg-rose-50 border-rose-400 text-rose-600 ring-rose-500/10"
