#include "CCAnchorNode.h"
#include "CCPointExtension.h"

NS_CC_BEGIN

void CCAnchorNode::setContentSize( const CCSize& contentSize )
{
	throw std::exception("The method or operation is not implemented.");
}

bool CCAnchorNode::init()
{
	CCNode::init();
	m_obAnchorPoint = ccp(0,0);
	m_obAnchorPointInPoints = ccp(0,0);
	m_obContentSize = CCSizeMake(0,0);
	return true;
}

void CCAnchorNode::setAnchorPoint( const CCPoint& anchorPoint )
{
	throw std::exception("The method or operation is not implemented.");
}

void CCAnchorNode::setAnchorPointInPoints( const CCPoint& anchorPointInPoints )
{
	m_obAnchorPointInPoints = anchorPointInPoints;
	m_bTransformDirty = m_bInverseDirty = true;
}

NS_CC_END