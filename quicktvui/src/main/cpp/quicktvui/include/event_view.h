#pragma once

#include "renderer/arkui/stack_node.h"
#include "renderer/arkui/text_node.h"
#include "renderer/components/custom_view.h"

namespace hippy {
inline namespace render {
inline namespace native {

class EventView : public CustomView {
  public:
  EventView(std::shared_ptr<NativeRenderContext> &ctx);
  virtual ~EventView();

  StackNode *GetLocalRootArkUINode() override;
  void CreateArkUINodeImpl() override;
  void DestroyArkUINodeImpl() override;
  bool SetPropImpl(const std::string &propKey, const HippyValue &propValue) override;

  void OnChildInsertedImpl(std::shared_ptr<BaseView> const &childView, int32_t index) override;
  void OnChildRemovedImpl(std::shared_ptr<BaseView> const &childView, int32_t index) override;

  private:
  std::shared_ptr<StackNode> stackNode_;
  std::shared_ptr<TextNode> textNode_;
};

} // namespace native
} // namespace render
} // namespace hippy
