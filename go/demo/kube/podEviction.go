package kube

import (
	"fmt"
	policyv1beta1 "k8s.io/api/policy/v1beta1"
)

import (
	"context"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	// uses the current context in kubeconfig
	// path-to-kubeconfig -- for example, /root/.kube/config
	config, _ := clientcmd.BuildConfigFromFlags("", "/root/.kube/config")
	// creates the clientset
	clientset, _ := kubernetes.NewForConfig(config)
	// access the API to list pods
	eviction := &policyv1beta1.Eviction{
		ObjectMeta: metav1.ObjectMeta{
			Name: "xxx",
			Namespace: "uat",
		},
	}

	err := clientset.PolicyV1beta1().Evictions("uat").Evict(context.TODO(), eviction)
	if err != nil {
		return 
	}

	fmt.Printf("evicedr\n")
}
